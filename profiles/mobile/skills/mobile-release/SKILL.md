# Mobile Release Preparation Workflow

When invoked, delegate to the `release-manager` agent and execute:

## Step 1 — Confirm Release Scope

Ask or infer:
- Platform: Android, iOS, or both?
- Version number (e.g., 2.4.0)?
- What changed since last release? (read CHANGELOG or git log)

## Step 2 — Validate Version Bump

**Android** — check `app/build.gradle.kts`:
```kotlin
versionCode = [must be > last release build number]
versionName = "[new semver]"
```

**iOS** — check `project.pbxproj` or `Info.plist`:
```
MARKETING_VERSION = [new semver];
CURRENT_PROJECT_VERSION = [must be > last release build number];
```

Flag if either is missing or incorrect.

## Step 3 — Run Release Checklist

Tick off each item by reading relevant files:

**Code Quality**
- [ ] No `TODO(release)` or `FIXME` comments in changed files
- [ ] No `BuildConfig.DEBUG` gated features accidentally enabled in release
- [ ] Lint passes (read lint report if present)

**Security**
- [ ] No secrets/keys in source (grep for common patterns)
- [ ] ProGuard/R8 enabled (Android) / Dead code stripping enabled (iOS)

**Strings & Assets**
- [ ] New strings localized (not hardcoded in code)
- [ ] New images added to asset catalog/drawable

**Dependencies**
- [ ] No snapshot/beta dependencies in release build

## Step 4 — Draft Release Notes

Generate user-facing release notes from:
- Git log since last release tag
- CHANGELOG.md (if present)

Format:
```
## What's New in [VERSION]

### New Features
• [Feature]: [one sentence user benefit]

### Improvements
• [What improved]: [why users care]

### Bug Fixes
• Fixed [symptom] that occurred when [context]
```

Keep each line under 80 characters.
Play Store limit: 500 characters per locale.
App Store limit: 4000 characters.

## Step 5 — Generate Build & Upload Commands

**Android (Fastlane):**
```bash
bundle exec fastlane deploy_internal    # internal testing track
bundle exec fastlane deploy_production rollout:0.1   # 10% rollout
```

**iOS (Fastlane):**
```bash
bundle exec fastlane beta              # TestFlight
bundle exec fastlane release           # App Store submission
```

**Manual fallback:**
```bash
# Android
./gradlew bundleRelease

# iOS
xcodebuild archive -scheme MyApp -configuration Release -archivePath ./build/MyApp.xcarchive
xcodebuild -exportArchive -archivePath ./build/MyApp.xcarchive -exportPath ./build -exportOptionsPlist ExportOptions.plist
```

## Step 6 — Output Summary

```
## Release [VERSION] — Summary

### Platform(s): [Android / iOS / Both]

### Version
- Android: versionCode=[N], versionName=[X.Y.Z]
- iOS: build=[N], version=[X.Y.Z]

### Checklist Status
[✓] Code quality
[✓] Security
[✗] BLOCKER: [describe issue]

### Release Notes (draft)
[Generated notes]

### Next Steps
1. [Action] — [owner]
2. [Action] — [owner]
```
