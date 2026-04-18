# Project Structure Conventions

## Android

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

## iOS

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
