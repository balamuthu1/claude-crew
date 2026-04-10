# Android Architecture Standards

These rules define the expected architecture patterns for Android projects in this team. Claude must apply and enforce these patterns.

---

## Chosen Architecture: MVVM + Clean Architecture

```
┌─────────────────────────────────────┐
│         Presentation Layer          │
│  Composable Screen → ViewModel      │
│  ViewModel → UiState (StateFlow)    │
└────────────────┬────────────────────┘
                 │ calls
┌────────────────▼────────────────────┐
│            Domain Layer             │
│  UseCase → Repository (interface)   │
│  Domain Models (pure Kotlin)        │
└────────────────┬────────────────────┘
                 │ implements
┌────────────────▼────────────────────┐
│             Data Layer              │
│  RepositoryImpl → Remote + Local    │
│  DTO ←→ Domain Mapper               │
└─────────────────────────────────────┘
```

**Dependency rule**: each layer depends only inward. Data layer knows nothing about Presentation.

---

## Layer Responsibilities

### Presentation

- **Composable screens**: render `UiState`, emit user events to ViewModel
- **ViewModel**: single source of truth for UI state; calls UseCases; never holds `Context` or `View`
- **UiState**: sealed class with `Loading`, `Success(data)`, `Error(message)` variants
- No network calls, no database calls, no business logic

```kotlin
// GOOD ViewModel structure
@HiltViewModel
class OrderViewModel @Inject constructor(
    private val placeOrder: PlaceOrderUseCase,
    private val getOrders: GetOrdersUseCase
) : ViewModel() {

    private val _state = MutableStateFlow<OrderUiState>(OrderUiState.Loading)
    val state: StateFlow<OrderUiState> = _state.asStateFlow()

    fun loadOrders() {
        viewModelScope.launch {
            _state.value = OrderUiState.Loading
            getOrders()
                .onSuccess { _state.value = OrderUiState.Success(it) }
                .onFailure { _state.value = OrderUiState.Error(it.message ?: "Error") }
        }
    }
}
```

### Domain

- Plain Kotlin classes — zero Android dependencies
- One public method per UseCase (`operator fun invoke()` or `execute()`)
- Repository interfaces defined here (implemented in data layer)
- Domain models: clean data classes, no `@Entity`, no `@SerializedName`

```kotlin
class PlaceOrderUseCase @Inject constructor(
    private val orderRepo: OrderRepository,
    private val inventoryRepo: InventoryRepository
) {
    suspend operator fun invoke(cart: Cart): Result<OrderConfirmation> {
        if (!inventoryRepo.hasStock(cart.items)) return Result.failure(OutOfStockError())
        return orderRepo.placeOrder(cart)
    }
}
```

### Data

- `RepositoryImpl` classes implement domain repository interfaces
- DTOs (network/DB models) mapped to domain models before returning
- **Single source of truth**: if both remote and local exist, Repository decides which to return
- Network errors mapped to domain errors (no Retrofit/OkHttp exceptions leak to domain)

```kotlin
class OrderRepositoryImpl @Inject constructor(
    private val api: OrderApiService,
    private val dao: OrderDao
) : OrderRepository {

    override fun getOrders(): Flow<Result<List<Order>>> = flow {
        emit(dao.getAll().map { it.toDomain() }.let { Result.success(it) })
        try {
            val remote = api.fetchOrders()
            dao.upsert(remote.map { it.toEntity() })
        } catch (e: IOException) {
            emit(Result.failure(NetworkError(e.message)))
        }
    }
}
```

---

## Dependency Injection (Hilt)

- `@HiltViewModel` for all ViewModels
- `@Singleton` for repositories and services (one instance per app lifecycle)
- `@ActivityRetainedScoped` for scopes tied to ViewModel lifecycle
- Modules go in `di/` package, named by what they provide: `NetworkModule`, `DatabaseModule`

```kotlin
@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {
    @Provides @Singleton
    fun provideRetrofit(@ApplicationContext ctx: Context): Retrofit = ...

    @Provides @Singleton
    fun provideOrderApi(retrofit: Retrofit): OrderApiService =
        retrofit.create(OrderApiService::class.java)
}
```

---

## Navigation (Compose Navigation)

- Single `NavHost` at the app root
- Routes defined as sealed classes or objects (type-safe)
- Pass only primitive IDs between screens — never pass full domain objects via nav args
- Coordinator-like pattern: ViewModel emits `UiEvent` for navigation; screen collects and calls `navController.navigate()`

```kotlin
sealed class Screen(val route: String) {
    object Home : Screen("home")
    data class OrderDetail(val orderId: String) : Screen("order/{orderId}") {
        companion object {
            fun route(id: String) = "order/$id"
        }
    }
}
```

---

## State Management

- `StateFlow` for all ViewModel state (never `LiveData` in new code)
- `Channel` + `Flow` for one-shot events (avoid `SingleLiveEvent` pattern)
- UI collects state with `collectAsStateWithLifecycle()` (respects lifecycle)

---

## Module Structure (multi-module projects)

```
:app                  ← application module, wires everything
:feature:orders       ← feature module (presentation + domain)
:feature:checkout     ← feature module
:core:data            ← shared data layer
:core:domain          ← shared domain models
:core:ui              ← shared design system / components
:core:testing         ← shared test utilities
```

Rule: feature modules depend on `:core:*`, never on each other.

---

## What to Avoid

| Pattern | Why | Alternative |
|---|---|---|
| `LiveData` in new code | StateFlow is preferred in Kotlin | `StateFlow` |
| `AsyncTask` | Deprecated | Coroutines |
| Singleton `Application` context passed everywhere | Tight coupling | Hilt `@ApplicationContext` |
| `EventBus` / `Otto` | Hard to trace | `SharedFlow` channels |
| God ViewModel (100+ lines) | Single responsibility | Split into multiple VMs or UseCases |
| Fragment backstack manipulation | Complex, bug-prone | Navigation Compose |
