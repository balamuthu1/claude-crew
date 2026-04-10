# Kotlin Coding Standards

These rules apply to all Kotlin files in Android projects. Claude must follow and enforce these in all code reviews and code generation.

---

## Naming

- Classes/Objects: `PascalCase`
- Functions/Variables: `camelCase`
- Constants: `SCREAMING_SNAKE_CASE` in companion objects or top-level
- Files: match primary class name (`UserRepository.kt`)
- Private properties: no underscore prefix (Kotlin convention differs from iOS)

```kotlin
// GOOD
const val MAX_RETRY_COUNT = 3
class UserRepository
fun fetchUser(id: String): User
private val activeSession: Session

// BAD
val _activeSession: Session   // underscore only for backing property pattern
val maxretrycount = 3
```

---

## Null Safety

- Prefer `?.` and `?:` over `!!`
- If `!!` is unavoidable, add `// Safe: [reason]` comment on the same line
- Use `requireNotNull(x)` when null is a programming error (throws with message)
- Use `checkNotNull(x)` for internal invariants

```kotlin
// BAD
val name = user!!.name

// GOOD
val name = user?.name ?: "Unknown"

// ACCEPTABLE (with justification)
val bitmap = view.drawable.toBitmap()  // Safe: drawable is set in XML and never null
```

---

## Collections & Immutability

- Always use read-only interfaces at API boundaries: `List<T>`, `Map<K,V>`, `Set<T>`
- Use `listOf()`, `mapOf()` for read-only; `mutableListOf()` internally
- Prefer `val` over `var` — mutate state via `StateFlow` emissions, not mutable vars

```kotlin
// BAD: exposes mutable list
class UserRepo {
    val users: MutableList<User> = mutableListOf()
}

// GOOD
class UserRepo {
    private val _users: MutableList<User> = mutableListOf()
    val users: List<User> get() = _users.toList()
}
```

---

## Functions & Lambdas

- Keep functions under 30 lines — extract if longer
- Use named arguments when passing 3+ values of the same type
- Extension functions for utility logic on external types
- Avoid deeply nested lambdas — extract to named functions

```kotlin
// BAD: ambiguous positional args
createUser("Alice", "alice@test.com", "ADMIN", true)

// GOOD: named args
createUser(name = "Alice", email = "alice@test.com", role = Role.ADMIN, active = true)
```

---

## Coroutines

- Use `viewModelScope` in ViewModel, `lifecycleScope` in Activity/Fragment
- `GlobalScope` is BANNED in production code
- `withContext(Dispatchers.IO)` for blocking I/O; `Dispatchers.Default` for CPU-heavy work
- Never use `runBlocking` in production (only acceptable in tests)
- Prefer structured concurrency: launch child coroutines in a coroutine scope

```kotlin
// BAD
GlobalScope.launch { fetchData() }

// GOOD
viewModelScope.launch {
    val result = withContext(Dispatchers.IO) { repository.fetchData() }
    _state.value = result.toUiState()
}
```

---

## Flow

- `StateFlow` for UI state (always has a value, replays to new collectors)
- `SharedFlow` for one-shot events (navigation, snackbar)
- Always collect with `collectAsStateWithLifecycle()` in Compose (not `collectAsState()`)
- Cancel flows when the lifecycle ends — use `repeatOnLifecycle`

```kotlin
// BAD: doesn't respect lifecycle
lifecycleScope.launch {
    viewModel.uiState.collect { render(it) }
}

// GOOD
lifecycleScope.launch {
    repeatOnLifecycle(Lifecycle.State.STARTED) {
        viewModel.uiState.collect { render(it) }
    }
}
```

---

## Sealed Classes & When Expressions

- Use `when` exhaustively on sealed classes (no `else` branch when sealed)
- Use sealed classes for `UiState`, `Result`, error types

```kotlin
sealed class UiState<out T> {
    object Loading : UiState<Nothing>()
    data class Success<T>(val data: T) : UiState<T>()
    data class Error(val message: String) : UiState<Nothing>()
}

// Exhaustive when — compiler catches missing cases
when (state) {
    is UiState.Loading -> showLoader()
    is UiState.Success -> showContent(state.data)
    is UiState.Error   -> showError(state.message)
}
```

---

## Compose-Specific Rules

- Composables must be stateless — accept state as params, emit events via lambdas
- No `ViewModel` or `hiltViewModel()` calls below the screen-level composable
- Use `@Preview` for every non-trivial composable
- Keys in `LazyColumn` must be stable and unique

```kotlin
// BAD: composable owns the ViewModel
@Composable
fun ItemRow(itemId: String) {
    val vm: ItemViewModel = hiltViewModel()  // violation: not screen-level
}

// GOOD: stateless, receives state
@Composable
fun ItemRow(item: Item, onDelete: () -> Unit) {
    Row { Text(item.title); IconButton(onClick = onDelete) { ... } }
}
```

---

## Error Handling

- Define a domain `AppError` sealed class — never propagate raw exceptions to UI
- Use `Result<T>` or a custom `Either<Error, T>` at repository boundaries
- Log errors with context: `Log.e(TAG, "fetch failed for userId=$id", e)`

---

## Logging

- Use `Timber` in production code (not `Log.*` directly)
- Never log PII (user ID, email, tokens) even in debug
- Remove `Timber.d` calls in critical hot paths (render loop, scroll)
