# Language Quick Reference

## Kotlin (Android)

- Null safety: prefer `?.let {}` and `?: return` over `!!`
- Coroutines: use `viewModelScope` / `lifecycleScope`, never `GlobalScope`
- State: `StateFlow` + `UiState` sealed class in ViewModel
- Compose: stateless composables, hoisted state, `remember` + `derivedStateOf`
- DI: Hilt (preferred), Koin acceptable
- Build: Gradle KTS, version catalogs (`libs.versions.toml`)

## Swift (iOS)

- Use `guard let` / `if let` over force unwrap
- Concurrency: Swift Concurrency (`async/await`, `Task`, `Actor`) over GCD
- SwiftUI: `@StateObject` for owned models, `@ObservedObject` for injected
- Combine: use `sink` with `store(in: &cancellables)` — never ignore the cancellable
- Memory: audit for retain cycles in closures (`[weak self]`)
- Modules: Swift Package Manager preferred over CocoaPods for new dependencies
