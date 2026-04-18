---
paths:
  - "**/*.kt"
  - "**/*.swift"
  - "**/AndroidManifest.xml"
  - "**/*.gradle"
  - "**/*.gradle.kts"
  - "**/*.xcodeproj/**"
  - "**/Podfile"
  - "**/Package.swift"
---

# Mobile Rules

## Kotlin

- Prefer `?.let` / `?:` over `!!`; if `!!` is unavoidable add `// Safe: <reason>` on the same line.
- `GlobalScope` is banned — use `viewModelScope` or `lifecycleScope`.
- Never `runBlocking` in production code (tests only).
- Use `StateFlow` for UI state; `SharedFlow` for one-shot events (navigation, snackbar).
- Collect flows with `collectAsStateWithLifecycle()` in Compose, not `collectAsState()`.
- Keep functions under 30 lines; use named args for 3+ same-type parameters.
- Use read-only interfaces (`List`, `Map`, `Set`) at API boundaries.
- Never log PII (user ID, email, tokens) even at debug level; use Timber, not `Log.*`.
- Composables must be stateless — accept state as params, emit events via lambdas.
- No `ViewModel` or `hiltViewModel()` calls below screen-level composables.

## Swift

- Never force unwrap (`!`) without a `// Safe: <reason>` comment on the same line.
- Use `guard let` at function entry for early exit; `if let` for inline optional use.
- All new async code uses `async/await` — no new `DispatchQueue` or completion handlers.
- Mark UI-updating types/functions `@MainActor`.
- Every `sink` must store its cancellable: `.store(in: &cancellables)` — never ignore.
- Closures outliving the call site must capture `[weak self]`; guard immediately after.
- Default to `struct` for data models; mark classes `final` unless designed for subclassing.
- No business logic in `View.body` — move to ViewModel.

## Android Architecture

- Dependency rule: Presentation → Domain ← Data. Each layer depends only inward.
- ViewModel: single source of truth; never holds `Context` or `View`; calls UseCases only.
- Domain layer: zero Android imports; one public method per UseCase.
- Never store sensitive data in plain `SharedPreferences` — use `EncryptedSharedPreferences`.
- Use `@HiltViewModel` and constructor injection for all ViewModel dependencies.
- No business logic in Composables, Activities, or Fragments.

## iOS Architecture

- MVVM: `@MainActor` ViewModel, `@Published` state, `ObservableObject` (or TCA if declared in config).
- Repository protocol lives in Domain layer; implementation in Data layer.
- Never store tokens or PII in `UserDefaults` — use Keychain.
