---
name: mobile-test
description: >
  Mobile test generation workflow. Given a feature or code file, generates a
  comprehensive test suite for Android (JUnit/MockK/Compose) or iOS (XCTest/SwiftUI).
  Invoke with /mobile-test <feature or file>.
---

# Mobile Test Generation Workflow

When invoked:

## Step 1 — Read the Subject

Read the file or feature description provided. Identify:
- What is the public API / contract of this component?
- What state transitions or behaviors exist?
- What dependencies need to be mocked?
- What can go wrong (error paths, nulls, network failures)?

## Step 2 — Classify What to Test

| Layer | Test Type | When |
|---|---|---|
| ViewModel / Presenter | Unit | Always |
| Use Case / Interactor | Unit | Always |
| Repository | Integration | When it has non-trivial logic |
| View / Composable | UI / Snapshot | For important screens |
| End-to-end flow | E2E | For critical user journeys |

## Step 3 — Generate Tests

### Android — ViewModel Test Template

```kotlin
@OptIn(ExperimentalCoroutinesApi::class)
class FeatureViewModelTest {

    @get:Rule
    val coroutineRule = MainCoroutineRule()   // replaces Main dispatcher with TestCoroutineDispatcher

    private lateinit var repo: FeatureRepository
    private lateinit var vm: FeatureViewModel

    @Before
    fun setup() {
        repo = mockk()
        vm = FeatureViewModel(GetFeatureUseCase(repo))
    }

    @Test
    fun `initial load succeeds and updates state to Success`() = runTest {
        val expected = fakeFeatureModel()
        coEvery { repo.fetchFeature(any()) } returns expected

        vm.uiState.test {
            assertIs<FeatureUiState.Loading>(awaitItem())
            val success = awaitItem()
            assertIs<FeatureUiState.Success>(success)
            assertEquals(expected, success.data)
            cancelAndIgnoreRemainingEvents()
        }
    }

    @Test
    fun `when repo throws, state becomes Error`() = runTest {
        coEvery { repo.fetchFeature(any()) } throws IOException("Network error")

        vm.uiState.test {
            awaitItem()  // Loading
            val error = awaitItem()
            assertIs<FeatureUiState.Error>(error)
            assertEquals("Network error", error.message)
            cancelAndIgnoreRemainingEvents()
        }
    }
}
```

### Android — Compose UI Test Template

```kotlin
@RunWith(AndroidJUnit4::class)
class FeatureScreenTest {

    @get:Rule
    val composeTestRule = createComposeRule()

    @Test
    fun loadingState_showsProgressIndicator() {
        composeTestRule.setContent {
            FeatureScreen(uiState = FeatureUiState.Loading)
        }
        composeTestRule.onNodeWithTag("loading_indicator").assertIsDisplayed()
    }

    @Test
    fun successState_showsFeatureTitle() {
        val model = fakeFeatureModel(title = "Test Feature")
        composeTestRule.setContent {
            FeatureScreen(uiState = FeatureUiState.Success(model))
        }
        composeTestRule.onNodeWithText("Test Feature").assertIsDisplayed()
    }

    @Test
    fun errorState_showsRetryButton() {
        composeTestRule.setContent {
            FeatureScreen(uiState = FeatureUiState.Error("Something went wrong"))
        }
        composeTestRule.onNodeWithText("Retry").assertIsDisplayed()
    }
}
```

### iOS — ViewModel Test Template

```swift
@MainActor
class FeatureViewModelTests: XCTestCase {
    var sut: FeatureViewModel!
    var mockRepo: MockFeatureRepository!

    override func setUp() async throws {
        mockRepo = MockFeatureRepository()
        sut = FeatureViewModel(useCase: GetFeatureUseCase(repository: mockRepo))
    }

    func test_load_success_updatesStateToLoaded() async throws {
        let expected = FeatureModel(id: "1", title: "Test", description: "Desc")
        mockRepo.result = .success(expected)

        await sut.load(id: "1")

        XCTAssertEqual(sut.state, .loaded(expected))
    }

    func test_load_networkFailure_updatesStateToError() async {
        mockRepo.result = .failure(URLError(.notConnectedToInternet))

        await sut.load(id: "1")

        if case .error(let msg) = sut.state {
            XCTAssertFalse(msg.isEmpty)
        } else {
            XCTFail("Expected error state, got \(sut.state)")
        }
    }

    func test_load_setsLoadingStateBeforeFetch() async {
        var states: [FeatureViewState] = []
        mockRepo.delay = 0.1   // simulate async
        mockRepo.result = .success(fakeModel)
        let cancellable = sut.$state.sink { states.append($0) }

        await sut.load(id: "1")

        XCTAssertEqual(states.first, .loading)
        cancellable.cancel()
    }
}
```

### iOS — Mock Protocol Template

```swift
final class MockFeatureRepository: FeatureRepository {
    var result: Result<FeatureModel, Error> = .failure(NSError(domain: "test", code: 0))
    var delay: TimeInterval = 0
    
    func fetchFeature(id: String) async throws -> FeatureModel {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        return try result.get()
    }
}
```

## Step 4 — Output

Produce:
1. The generated test file(s) with proper imports, setup, and teardown
2. A list of any test helpers / fakes needed
3. Commands to run the tests:
   - Android: `./gradlew test` or `./gradlew connectedAndroidTest`
   - iOS: `xcodebuild test -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 16'`
