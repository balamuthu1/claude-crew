# Android Feature Development Workflow

When invoked, follow these steps in order:

## Step 1 — Understand the Feature

Ask or infer:
- What is the user-facing behavior?
- Does it require network calls? Local storage? Background work?
- Which existing screens/flows does it touch?
- What are the edge cases (empty state, error, loading, offline)?

## Step 2 — Design the Architecture

Produce a file structure skeleton before writing any code:

```
feature-name/
  presentation/
    FeatureScreen.kt          ← Compose UI
    FeatureViewModel.kt       ← StateFlow<FeatureUiState>
    FeatureUiState.kt         ← sealed class
    FeatureUiEvent.kt         ← one-shot events (navigation, snackbar)
  domain/
    GetFeatureDataUseCase.kt  ← orchestrates data fetch
    FeatureModel.kt           ← domain model (not API model)
  data/
    FeatureRepository.kt      ← interface
    FeatureRepositoryImpl.kt  ← implementation
    remote/
      FeatureApiService.kt    ← Retrofit interface
      FeatureDto.kt           ← JSON model
    local/
      FeatureDao.kt           ← Room DAO (if persisted)
      FeatureEntity.kt        ← Room entity
  di/
    FeatureModule.kt          ← Hilt bindings
```

## Step 3 — Implement in This Order

1. **Domain layer first** — models, use case interface, repository interface
   - Pure Kotlin, no Android dependencies
   - Write unit tests immediately

2. **Data layer** — DTO, API service, DAO, repository implementation
   - Use Retrofit + Moshi/Gson for network
   - Use Room for local persistence
   - Map DTOs → domain models in the repository

3. **ViewModel** — UiState sealed class, StateFlow, calls use case
   ```kotlin
   @HiltViewModel
   class FeatureViewModel @Inject constructor(
       private val getFeatureData: GetFeatureDataUseCase
   ) : ViewModel() {

       private val _uiState = MutableStateFlow<FeatureUiState>(FeatureUiState.Loading)
       val uiState: StateFlow<FeatureUiState> = _uiState.asStateFlow()

       init { loadData() }

       private fun loadData() {
           viewModelScope.launch {
               _uiState.value = FeatureUiState.Loading
               getFeatureData()
                   .onSuccess { _uiState.value = FeatureUiState.Success(it) }
                   .onFailure { _uiState.value = FeatureUiState.Error(it.message ?: "Unknown error") }
           }
       }
   }

   sealed class FeatureUiState {
       object Loading : FeatureUiState()
       data class Success(val data: FeatureModel) : FeatureUiState()
       data class Error(val message: String) : FeatureUiState()
   }
   ```

4. **Compose UI** — collect state, render screens
   ```kotlin
   @Composable
   fun FeatureScreen(viewModel: FeatureViewModel = hiltViewModel()) {
       val uiState by viewModel.uiState.collectAsStateWithLifecycle()

       when (uiState) {
           is FeatureUiState.Loading -> LoadingIndicator()
           is FeatureUiState.Success -> FeatureContent((uiState as FeatureUiState.Success).data)
           is FeatureUiState.Error -> ErrorMessage((uiState as FeatureUiState.Error).message)
       }
   }
   ```

5. **Hilt Module** — bind repository, provide use case

6. **Navigation** — add route to NavGraph

## Step 4 — Write Tests

For each layer:

| Layer | Test type | Framework |
|---|---|---|
| ViewModel | Unit | JUnit + MockK + Turbine |
| UseCase | Unit | JUnit + MockK |
| Repository | Integration | Room in-memory + MockWebServer |
| Compose UI | UI | Compose Test Rule |

Minimum test coverage for the feature:
- [ ] ViewModel: loading state → success state
- [ ] ViewModel: loading state → error state
- [ ] ViewModel: retry logic (if applicable)
- [ ] Repository: successful response mapped correctly
- [ ] Repository: network error mapped to domain error
- [ ] UI: loading state renders correctly
- [ ] UI: success state shows expected content
- [ ] UI: error state shows error message

## Step 5 — Pre-Merge Checklist

- [ ] `./gradlew lint` passes with no new errors
- [ ] `./gradlew test` all unit tests pass
- [ ] No hardcoded strings (use `strings.xml`)
- [ ] Content descriptions on all interactive icons
- [ ] ProGuard rules added if needed (new library or reflection)
- [ ] No `TODO` left uncommitted
- [ ] Feature flagged if partial (not fully ready for production)
