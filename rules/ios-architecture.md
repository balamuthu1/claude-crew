# iOS Architecture Standards

These rules define the expected architecture patterns for iOS projects in this team. Claude must apply and enforce these patterns.

---

## Chosen Architecture: MVVM + Clean Architecture (SwiftUI)

```
┌─────────────────────────────────────┐
│         Presentation Layer          │
│   SwiftUI View → ViewModel          │
│   ViewModel → @Published state      │
└────────────────┬────────────────────┘
                 │ calls
┌────────────────▼────────────────────┐
│            Domain Layer             │
│  UseCase → Repository (protocol)    │
│  Domain Models (pure Swift)         │
└────────────────┬────────────────────┘
                 │ implements
┌────────────────▼────────────────────┐
│             Data Layer              │
│  RepositoryImpl → Network + Local   │
│  DTO ←→ Domain Mapper               │
└─────────────────────────────────────┘
```

**Dependency rule**: each layer depends only inward. Data knows nothing about Presentation.

---

## Layer Responsibilities

### Presentation

- **SwiftUI Views**: pure rendering — no business logic, no direct data access
- **ViewModel** (`@MainActor ObservableObject`): owns `@Published` state, calls UseCases
- Views are owned via `@StateObject`; injected ViewModels via `@ObservedObject`
- Navigation: `NavigationStack` + `NavigationPath` (iOS 16+); Coordinator for UIKit

```swift
@MainActor
final class OrderViewModel: ObservableObject {
    enum State: Equatable {
        case idle, loading, loaded([Order]), error(String)
    }
    
    @Published private(set) var state: State = .idle
    private let getOrders: GetOrdersUseCase
    private var loadTask: Task<Void, Never>?
    
    init(getOrders: GetOrdersUseCase) {
        self.getOrders = getOrders
    }
    
    func loadOrders() {
        loadTask?.cancel()
        loadTask = Task {
            state = .loading
            do {
                let orders = try await getOrders.execute()
                guard !Task.isCancelled else { return }
                state = .loaded(orders)
            } catch {
                state = .error(error.localizedDescription)
            }
        }
    }
}
```

### Domain

- Pure Swift structs/enums — no UIKit, no Foundation networking
- Repository protocols (interfaces) defined here
- One public method per UseCase (`execute()` or `callAsFunction()`)
- Domain models: plain structs, no `Codable` unless needed for storage

```swift
struct GetOrdersUseCase {
    let repository: OrderRepository
    
    func execute() async throws -> [Order] {
        try await repository.fetchOrders()
    }
}

protocol OrderRepository {
    func fetchOrders() async throws -> [Order]
    func placeOrder(_ cart: Cart) async throws -> OrderConfirmation
}
```

### Data

- `RepositoryImpl` conforms to the domain protocol
- DTOs (`Codable` structs) mapped to domain models before returning
- Network errors caught and re-thrown as domain `AppError`
- Local persistence (Core Data / SwiftData) isolated behind another protocol

```swift
final class OrderRepositoryImpl: OrderRepository {
    private let apiClient: APIClient
    private let localStore: OrderStore
    
    func fetchOrders() async throws -> [Order] {
        do {
            let dtos: [OrderDTO] = try await apiClient.get("/orders")
            let orders = dtos.map { $0.toDomain() }
            try await localStore.save(orders)
            return orders
        } catch let urlError as URLError {
            throw AppError.network(urlError)
        }
    }
}
```

---

## Dependency Injection

- Constructor injection (not service locator / `@EnvironmentObject` for business deps)
- Factory / Assembly pattern for wiring at the composition root

```swift
// Composition root (at app startup or coordinator)
struct AppAssembly {
    static func makeOrdersViewModel() -> OrderViewModel {
        let client = URLSessionAPIClient(session: .shared)
        let store = CoreDataOrderStore()
        let repo = OrderRepositoryImpl(apiClient: client, localStore: store)
        let useCase = GetOrdersUseCase(repository: repo)
        return OrderViewModel(getOrders: useCase)
    }
}
```

---

## Navigation

**SwiftUI (iOS 16+):**
```swift
// NavigationStack with path-based navigation
struct AppView: View {
    @State private var path = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $path) {
            HomeView()
                .navigationDestination(for: OrderID.self) { id in
                    OrderDetailView(id: id, vm: AppAssembly.makeOrderDetailVM(id))
                }
        }
    }
}
```

**UIKit (Coordinator):**
```swift
protocol Coordinator: AnyObject {
    func start()
}

final class OrdersCoordinator: Coordinator {
    private let navigationController: UINavigationController
    
    func start() {
        let vm = AppAssembly.makeOrdersViewModel()
        let vc = OrdersViewController(viewModel: vm)
        vc.coordinator = self
        navigationController.pushViewController(vc, animated: true)
    }
    
    func showDetail(for id: OrderID) { ... }
}
```

---

## State Management

- Single `@Published` state property (enum with associated values) per ViewModel
- `@Observable` macro preferred for iOS 17+ (replaces `ObservableObject`)
- Avoid scattering `@Published` across 10 different booleans — consolidate into a state enum

```swift
// BAD: scattered state
@Published var isLoading = false
@Published var orders: [Order] = []
@Published var errorMessage: String?

// GOOD: consolidated state
@Published private(set) var state: OrderState = .idle
```

---

## Offline-First

```swift
func fetchOrders() async throws -> [Order] {
    // 1. Return cached data immediately (optimistic UI)
    let cached = try await localStore.load()
    if !cached.isEmpty { return cached }
    
    // 2. Fetch from remote, update cache
    let remote: [OrderDTO] = try await apiClient.get("/orders")
    let orders = remote.map { $0.toDomain() }
    try await localStore.save(orders)
    return orders
}
```

---

## What to Avoid

| Pattern | Why | Alternative |
|---|---|---|
| Force unwrap (`!`) without comment | Runtime crash risk | `guard let` / `??` |
| Logic in `View.body` | Hard to test, causes re-renders | ViewModel property |
| `AppDelegate` / `SceneDelegate` as service locator | Global mutable state | Composition root + DI |
| Massive ViewControllers | No separation of concerns | MVVM + UseCase |
| `NotificationCenter` for app-level state | Implicit coupling, no type safety | `@Published` / Combine / async stream |
| `DispatchQueue` in new code | Deprecated concurrency model | `async/await` + `Actor` |
| VIPER for new features | Excessive boilerplate in modern Swift | MVVM + Clean |
| `AnyView` type erasure | Kills SwiftUI diffing | Generic views or `@ViewBuilder` |
