# Swift Coding Standards

These rules apply to all Swift files in iOS projects. Claude must follow and enforce these in all code reviews and code generation.

---

## Naming

- Types/Protocols: `PascalCase`
- Functions/Variables/Properties: `camelCase`
- Constants: `camelCase` (Swift convention, not screaming snake)
- Abbreviations: capitalize fully in type names (`URL`, `HTTP`), lowercase in vars (`urlString`)
- Booleans: use `is`, `has`, `should`, `can` prefix (`isLoading`, `hasError`)

```swift
// GOOD
struct UserProfile { }
let maxRetryCount = 3
var isLoading = false
func fetchUser(withID id: String) -> User

// BAD
struct userProfile { }
let MAX_RETRY = 3
var loading = false
```

---

## Optionals

- Never force unwrap (`!`) without a `// Safe: <reason>` comment
- Prefer `guard let` at function entry for early exit
- Use `if let` for inline use of an optional value
- Use `??` for simple fallback values
- Avoid optional chaining chains more than 3 deep — break into `guard let`

```swift
// BAD
let name = user!.profile!.name!

// GOOD
guard let user = user else { return }
let name = user.profile?.name ?? "Unknown"
```

---

## Value Types vs Reference Types

- Default to `struct` for data models (value semantics, thread-safe by default)
- Use `class` when: identity matters, reference sharing is needed, subclassing required
- `enum` with associated values for discriminated unions / result types
- Mark classes `final` unless designed for subclassing

```swift
// GOOD: struct for data
struct UserProfile: Equatable, Codable {
    let id: String
    let name: String
}

// GOOD: class for services that hold state
final class NetworkClient {
    private let session: URLSession
    ...
}
```

---

## Concurrency (Swift Concurrency)

- Use `async/await` for all new async code — no new `DispatchQueue` or completion handlers
- Mark UI-updating types/functions `@MainActor`
- Use `Actor` for shared mutable state (replaces `DispatchQueue` serial queues)
- Handle `Task` cancellation: check `Task.isCancelled` or use `withTaskCancellationHandler`
- Store `Task` references to cancel on `deinit` or lifecycle end

```swift
// BAD: callback-based
func loadUser(id: String, completion: @escaping (Result<User, Error>) -> Void) { ... }

// GOOD: async/await
func loadUser(id: String) async throws -> User { ... }

// GOOD: MainActor on ViewModel
@MainActor
final class UserViewModel: ObservableObject {
    @Published private(set) var user: User?
}
```

---

## Combine

- Every `sink` must have its cancellable stored: `sink { }.store(in: &cancellables)`
- Never ignore the return value of `sink` / `assign`
- Prefer `assign(to:on:)` for simple bindings; use `sink` for side effects
- For new code, prefer `async/await` + `AsyncStream` over Combine pipelines

```swift
// BAD: fire-and-forget sink (memory leak and no cancellation)
publisher.sink { print($0) }

// GOOD
publisher
    .sink { [weak self] value in self?.handle(value) }
    .store(in: &cancellables)
```

---

## Memory Management

- Closures that outlive the call site capturing `self` must use `[weak self]`
- Delegate properties: always `weak var`
- After `[weak self]`, guard at the top of the closure: `guard let self else { return }`
- `deinit` should release resources: cancel tasks, remove observers

```swift
// BAD: retain cycle
networkClient.fetch { result in
    self.update(result)   // self holds networkClient, networkClient holds closure
}

// GOOD
networkClient.fetch { [weak self] result in
    guard let self else { return }
    self.update(result)
}
```

---

## SwiftUI

- Keep `body` simple — extract subviews into their own `View` structs
- `@StateObject` for ViewModels owned by this view
- `@ObservedObject` for ViewModels injected from outside
- `@EnvironmentObject` sparingly — only for app-wide state
- `@State` for simple local UI state only
- No business logic in `View.body` — move to ViewModel

```swift
// BAD: business logic in body
var body: some View {
    let sorted = items.sorted { $0.date > $1.date }  // O(n log n) per render
    List(sorted) { ... }
}

// GOOD: pre-sorted in ViewModel
var body: some View {
    List(viewModel.sortedItems) { ... }
}
```

---

## Error Handling

- Define typed `enum Error: LocalizedError` for domain errors
- Use `throw`/`try` over completion blocks with optional error
- Never swallow errors silently — at minimum, log them
- User-facing error messages come from `LocalizedError.errorDescription`

```swift
enum AppError: LocalizedError {
    case networkUnavailable
    case invalidResponse(code: Int)
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .networkUnavailable: return "No internet connection."
        case .invalidResponse(let code): return "Server error (\(code))."
        case .unauthorized: return "Please sign in again."
        }
    }
}
```

---

## Testing Hygiene

- All mocks implement protocols — never mock concrete types
- Test file name matches subject: `FeatureViewModelTests.swift`
- `setUp` creates the SUT; `tearDown` cancels tasks/clears state
- Don't `sleep()` in tests — use `async/await` or `XCTestExpectation` with timeout
