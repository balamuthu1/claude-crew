# iOS Feature Development Workflow

When invoked, follow these steps in order:

## Step 1 — Understand the Feature

Ask or infer:
- What is the user-facing behavior?
- Network calls? Local persistence? Background tasks?
- Which existing screens/flows does it touch?
- Edge cases: empty state, error, loading, offline, slow network?

## Step 2 — Design the Architecture

Produce a module skeleton before writing code:

```
Feature/
  Domain/
    FeatureModel.swift              ← domain struct/class
    FeatureRepositoryProtocol.swift ← data contract
    GetFeatureUseCase.swift         ← orchestrates fetch logic
  Data/
    FeatureRepositoryImpl.swift     ← conforms to protocol
    FeatureDTO.swift                ← Codable network model
    FeatureMapper.swift             ← DTO → domain model
    local/
      FeatureStore.swift            ← Core Data / SwiftData store
  Presentation/
    FeatureViewModel.swift          ← @MainActor, @Published state
    FeatureView.swift               ← SwiftUI view
    FeatureViewState.swift          ← enum for view states
  DI/
    FeatureAssembly.swift           ← factory / DI wiring
```

## Step 3 — Implement in This Order

### 1. Domain Layer

Pure Swift, zero UIKit/SwiftUI/Foundation-network dependencies.

```swift
struct FeatureModel: Equatable {
    let id: String
    let title: String
    let description: String
}

protocol FeatureRepository {
    func fetchFeature(id: String) async throws -> FeatureModel
}

struct GetFeatureUseCase {
    let repository: FeatureRepository

    func execute(id: String) async throws -> FeatureModel {
        try await repository.fetchFeature(id: id)
    }
}
```

### 2. Data Layer

```swift
struct FeatureDTO: Codable {
    let id: String
    let title: String
    let desc: String   // API naming may differ from domain
}

extension FeatureDTO {
    func toDomain() -> FeatureModel {
        FeatureModel(id: id, title: title, description: desc)
    }
}

final class FeatureRepositoryImpl: FeatureRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchFeature(id: String) async throws -> FeatureModel {
        let dto: FeatureDTO = try await apiClient.get("/features/\(id)")
        return dto.toDomain()
    }
}
```

### 3. ViewModel

```swift
enum FeatureViewState: Equatable {
    case idle
    case loading
    case loaded(FeatureModel)
    case error(String)
}

@MainActor
final class FeatureViewModel: ObservableObject {
    @Published private(set) var state: FeatureViewState = .idle

    private let useCase: GetFeatureUseCase
    private var loadTask: Task<Void, Never>?

    init(useCase: GetFeatureUseCase) {
        self.useCase = useCase
    }

    func load(id: String) {
        loadTask?.cancel()
        loadTask = Task {
            state = .loading
            do {
                let model = try await useCase.execute(id: id)
                guard !Task.isCancelled else { return }
                state = .loaded(model)
            } catch is CancellationError {
                // silently ignore
            } catch {
                state = .error(error.localizedDescription)
            }
        }
    }
}
```

### 4. SwiftUI View

```swift
struct FeatureView: View {
    @StateObject private var viewModel: FeatureViewModel
    let featureId: String

    init(featureId: String, viewModel: FeatureViewModel) {
        self.featureId = featureId
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                ProgressView()
            case .loaded(let model):
                FeatureContentView(model: model)
            case .error(let message):
                ErrorView(message: message) {
                    viewModel.load(id: featureId)
                }
            }
        }
        .task { viewModel.load(id: featureId) }
        .navigationTitle("Feature")
    }
}
```

### 5. DI Wiring

```swift
struct FeatureAssembly {
    static func makeViewModel(featureId: String) -> FeatureViewModel {
        let apiClient = APIClient.shared
        let repo = FeatureRepositoryImpl(apiClient: apiClient)
        let useCase = GetFeatureUseCase(repository: repo)
        return FeatureViewModel(useCase: useCase)
    }
}
```

## Step 4 — Write Tests

| Layer | Test | Framework |
|---|---|---|
| ViewModel | Unit | XCTest async/await |
| UseCase | Unit | XCTest |
| Repository | Integration | URLProtocol mock |
| View | Snapshot | swift-snapshot-testing |
| UI flow | E2E | XCUITest |

Minimum coverage:
- [ ] ViewModel: idle → loading → loaded
- [ ] ViewModel: idle → loading → error
- [ ] ViewModel: cancels in-flight task on re-load
- [ ] Repository: success response deserialized and mapped correctly
- [ ] Repository: HTTP 4xx/5xx maps to domain error
- [ ] View: loading state renders ProgressView
- [ ] View: error state shows retry button

## Step 5 — Pre-Merge Checklist

- [ ] `swiftlint` passes (or suppressions documented)
- [ ] All tests pass: `xcodebuild test -scheme MyApp`
- [ ] No force unwrap (`!`) without `// Safe:` comment
- [ ] VoiceOver labels on interactive elements
- [ ] `[weak self]` in all async closures
- [ ] No `UserDefaults` for sensitive data
- [ ] Strings in `Localizable.strings` (not hardcoded)
- [ ] Preview provider exists for new views
