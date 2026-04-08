# Claude Crew — Project Architecture Config
#
# This file tells Claude Crew agents what YOUR project actually uses.
# Agents read this before applying any rules, so they review against
# YOUR architecture — not a default one.
#
# Run `/detect-arch` to auto-generate this from your build files.
# Edit manually to correct or override anything the detector got wrong.
# Commit this file alongside your code so the whole team benefits.
# ─────────────────────────────────────────────────────────────────────

## Platform
# android | ios | both | react-native | flutter
platform: android

## Architecture Pattern
# android: mvvm | mvi | mvp | mvc | redux
# ios:     mvvm | mvi | viper | tca | mvc
pattern: mvvm

## Presentation Layer
# android: compose | xml | mixed
# ios:     swiftui | uikit | mixed
ui: compose

## State Management
# android: coroutines-flow | rxjava2 | rxjava3 | livedata | stateflow
# ios:     combine | async-await | rxswift | callbacks
state: coroutines-flow

## Dependency Injection
# android: hilt | koin | dagger2 | manual | anvil
# ios:     swinject | needle | manual | resolver
di: hilt

## Networking
# android: retrofit | ktor | volley | okhttp-manual
# ios:     urlsession | alamofire | moya
networking: retrofit

## Local Storage
# android: room | realm | sqlite-manual | datastore | none
# ios:     coredata | swiftdata | realm | userdefaults | none
storage: room

## Image Loading (Android)
# coil | glide | picasso | fresco | none
images: coil

## Testing Framework
# android: junit4 | junit5
# ios:     xctest | quick-nimble
test-framework: junit4

## Test Doubles
# android: mockk | mockito | manual-fakes
# ios:     protocol-mocks | ocmock | manual-fakes
mocking: mockk

## Navigation
# android: navigation-compose | navigation-fragment | manual | deeplink-only
# ios:     navigation-stack | coordinator | tab-bar-controller | manual
navigation: navigation-compose

## Build System (Android)
# gradle-kts | gradle-groovy
build: gradle-kts

## Package Manager (iOS)
# spm | cocoapods | carthage | mixed
# package-manager: spm

## Legacy Considerations
# Free text — describe anything agents must NOT suggest or must handle carefully.
# Examples:
#   "No Compose — XML-only, migration not planned"
#   "RxJava2, not migrating to coroutines"
#   "Dagger2 with custom component hierarchy, do not suggest Hilt migration"
#   "Mixed: new screens use Compose, old screens are XML — both are correct"
legacy-notes: ""

## Minimum SDK / OS
# android-min-sdk: 24
# ios-deployment-target: 16.0

## Modules (multi-module projects)
# List modules so agents understand the project boundary.
# Leave empty for single-module projects.
modules: []
# modules:
#   - :app
#   - :feature:auth
#   - :feature:checkout
#   - :core:data
#   - :core:domain
#   - :core:ui
