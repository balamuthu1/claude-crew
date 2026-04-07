# Claude Crew — Mobile Agent Harness

You are operating inside a Claude Code agent harness built for **Android and iOS mobile engineering teams**. The rules, agents, skills, and hooks in this repository configure your behavior for mobile development workflows.

---

## Core Behavior Rules

### Always

- Treat Kotlin and Swift as first-class languages with modern idioms (no Java-style Kotlin, no ObjC-style Swift)
- Apply platform-specific architecture patterns (see `rules/android-architecture.md`, `rules/ios-architecture.md`)
- Check for OWASP Mobile Top 10 risks when touching networking, storage, or auth code
- Flag UI changes that may break accessibility (content descriptions, semantic labels, contrast)
- Prefer coroutines/Flow over RxJava on Android; Combine/async-await over callbacks on iOS
- Respect existing architecture — don't introduce a new pattern into an existing codebase without flagging it

### Never

- Suggest `Thread.sleep()`, `runBlocking` in production Android code
- Use `force unwrap` (`!`) in Swift without a clear justification comment
- Store sensitive data (tokens, PII) in SharedPreferences/UserDefaults without encryption
- Suppress lint warnings without an inline explanation
- Call API methods on the main thread
- Delete or overwrite migration files, keystore files, or provisioning profiles without explicit user confirmation

---

## Agent Dispatch

When the user's request maps to a specialized domain, delegate using subagents:

| Trigger | Agent to use |
|---|---|
| "review this Android / Kotlin code" | `android-reviewer` |
| "review this iOS / Swift code" | `ios-reviewer` |
| "help me design the architecture" | `mobile-architect` |
| "app is slow / ANR / jank" | `mobile-performance` |
| "security audit / pentest" | `mobile-security` |
| "write tests / test plan" | `mobile-test-planner` |
| "prepare release / release notes" | `release-manager` |
| "accessibility audit / a11y" | `ui-accessibility` |

---

## Language Quick Reference

### Kotlin (Android)

- Null safety: prefer `?.let {}` and `?: return` over `!!`
- Coroutines: use `viewModelScope` / `lifecycleScope`, never `GlobalScope`
- State: `StateFlow` + `UiState` sealed class in ViewModel
- Compose: stateless composables, hoisted state, `remember` + `derivedStateOf`
- DI: Hilt (preferred), Koin acceptable
- Build: Gradle KTS, version catalogs (`libs.versions.toml`)

### Swift (iOS)

- Use `guard let` / `if let` over force unwrap
- Concurrency: Swift Concurrency (`async/await`, `Task`, `Actor`) over GCD
- SwiftUI: `@StateObject` for owned models, `@ObservedObject` for injected
- Combine: use `sink` with `store(in: &cancellables)` — never ignore the cancellable
- Memory: audit for retain cycles in closures (`[weak self]`)
- Modules: Swift Package Manager preferred over CocoaPods for new dependencies

---

## Project Structure Conventions

### Android

```
app/
  src/
    main/
      java/com.example.app/
        data/          # repositories, data sources, models
        domain/        # use cases, domain models, interfaces
        presentation/  # ViewModels, UI state, Compose screens
        di/            # Hilt modules
    test/              # Unit tests (JUnit + MockK)
    androidTest/       # Instrumented UI tests (Espresso / Compose UI Test)
```

### iOS

```
App/
  Sources/
    Domain/            # Models, use cases, repository protocols
    Data/              # Repository implementations, network, persistence
    Presentation/      # ViewModels, SwiftUI views, UIKit controllers
    Core/              # DI, extensions, utilities
  Tests/               # XCTest unit tests
  UITests/             # XCUITest UI tests
```

---

## Code Review Checklist (always apply)

- [ ] No business logic in Views/Activities/Fragments/ViewControllers
- [ ] No hardcoded strings that should be in resources
- [ ] No API keys or secrets committed
- [ ] Network calls wrapped in try/catch or Result type
- [ ] Lifecycle-aware: no leaks, no crashes on config change
- [ ] Accessibility: content descriptions, minimum touch target 48dp/44pt
- [ ] Tests exist for new public APIs and business logic

---

## Hooks

Hooks are shell scripts in `hooks/` invoked by Claude Code at lifecycle events. They are configured in `.claude/settings.json`.

- `pre-tool-use.sh` — runs before any tool execution (guards destructive ops)
- `post-tool-use.sh` — runs after file edits (reminds to lint/test)

---

## Skills

Skills are structured workflows in `skills/`. Invoke them with:

```
/android-feature   Build a new Android feature end-to-end
/ios-feature       Build a new iOS feature end-to-end
/mobile-test       Generate a test plan for a feature
/mobile-release    Walk through the mobile release checklist
```

---

## Rules

Detailed coding standards live in `rules/`:

- `rules/kotlin.md` — Kotlin style and patterns
- `rules/swift.md` — Swift style and patterns
- `rules/android-architecture.md` — Android architecture decisions
- `rules/ios-architecture.md` — iOS architecture decisions
