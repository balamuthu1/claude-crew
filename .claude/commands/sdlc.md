Run a full mobile SDLC for the feature described in the argument.

You are the **orchestrator**. Do NOT handle any stage yourself — spawn a dedicated
sub-agent for each stage using the `Agent` tool. Each sub-agent gets an isolated
context window focused on its domain.

---

## How to Orchestrate

For every stage below, call the `Agent` tool with:
- `description`: the stage label
- `prompt`: built from the template below (inject feature + platform + prior stage output)

**For stages 5 and 6 (security + accessibility): call `Agent` twice in a single
message to run them in parallel.**

After all stages complete, print the SDLC Summary Report.

---

## Stage Definitions

### Stage 1 — PLAN
Agent prompt:
```
You are the mobile-architect agent.

Feature: {{FEATURE}}
Platform: {{PLATFORM}}

Produce:
1. Architecture pattern choice (MVVM/MVI/TCA) with rationale
2. File/module structure skeleton (real paths, not pseudocode)
3. Layer breakdown: Domain → Data → Presentation
4. DI wiring, navigation approach, offline strategy if relevant

Rules (Android): Hilt DI, Coroutines/Flow, Compose, Clean Architecture
Rules (iOS): Constructor DI, async/await, SwiftUI, Clean Architecture
Output must be a complete skeleton a developer can start from immediately.
```
Tools to allow: Read, Glob

Gate: Print the architecture decision and ask "Proceed to BUILD? [y/N]"

---

### Stage 2 — BUILD
Agent prompt:
```
You are the mobile feature builder.

Feature: {{FEATURE}}
Platform: {{PLATFORM}}

Architecture from planning stage:
{{PLAN_OUTPUT}}

Implement the full feature skeleton in this order:
1. Domain: models, repository interface, use case
2. Data: DTO, API service, repository implementation, mapper
3. ViewModel + UiState sealed class
4. UI: Compose screen (Android) or SwiftUI view (iOS)
5. DI module wiring
6. Navigation route registration

Write real, compilable code. File by file. No pseudocode.
```
Tools to allow: Read, Write, Edit, Glob

Gate: Show file list created and ask "Proceed to TEST? [y/N]"

---

### Stage 3 — TEST
Agent prompt:
```
You are the mobile test planner.

Feature: {{FEATURE}}
Platform: {{PLATFORM}}

Implementation from build stage:
{{BUILD_OUTPUT}}

Generate a complete test suite:
- ViewModel unit tests: loading→success, loading→error, retry
- UseCase unit tests: business rules
- Repository integration tests: success path, network error → domain error
- UI test: main happy path

Android: JUnit 4 + MockK + runTest + Turbine for Flow assertions
iOS: XCTest + @MainActor + async/await + protocol mocks

Write complete test files with imports and setup/teardown.
```
Tools to allow: Read, Write, Edit, Glob

Gate: Show test file list and ask "Proceed to REVIEW? [y/N]"

---

### Stage 4 — CODE REVIEW
Agent prompt:
```
You are the mobile code reviewer.

Feature: {{FEATURE}}
Platform: {{PLATFORM}}

Review all code written in the build stage:
{{BUILD_OUTPUT}}

Apply standards from rules/kotlin.md (Android) or rules/swift.md (iOS)
and rules/android-architecture.md or rules/ios-architecture.md.

Output format:
## Code Review
### Critical (block merge)
- [FILE:LINE] Issue — Why — Fix
### Major (fix before release)
### Minor (improvements)
### Positive Observations
```
Tools to allow: Read, Grep, Glob

Gate: If Critical issues found, list them and ask "Issues found. Proceed anyway? [y/N]"

---

### Stage 5 — SECURITY  ← spawn in PARALLEL with Stage 6
Agent prompt:
```
You are the mobile security auditor.

Feature: {{FEATURE}}
Platform: {{PLATFORM}}

Audit this code for OWASP Mobile Top 10:
{{BUILD_OUTPUT}}

For each finding:
- Cite OWASP category (M1–M10)
- FILE:LINE reference
- Working code fix (not just description)
- Severity: Critical / High / Medium / Low

Focus areas: credential storage, network security, input validation,
exported components, binary protections.
```
Tools to allow: Read, Grep, Glob

---

### Stage 6 — ACCESSIBILITY  ← spawn in PARALLEL with Stage 5
Agent prompt:
```
You are the mobile accessibility auditor.

Feature: {{FEATURE}}
Platform: {{PLATFORM}}

Audit all UI code for WCAG 2.1 AA compliance:
{{BUILD_OUTPUT}}

Check:
- Every interactive element has contentDescription / accessibilityLabel
- Touch targets ≥ 48dp (Android) / 44pt (iOS)
- Text uses sp / Dynamic Type (not hardcoded px)
- Color contrast ≥ 4.5:1 for normal text
- Focus order is logical
- Loading/error states announced to screen reader

For each issue: WCAG criterion, FILE:LINE, code fix.
```
Tools to allow: Read, Grep, Glob

After both Stage 5 and Stage 6 complete, print their combined findings.
Gate: Ask "Proceed to RELEASE prep? [y/N]"

---

### Stage 7 — RELEASE
Agent prompt:
```
You are the mobile release manager.

Feature: {{FEATURE}}
Platform: {{PLATFORM}}
Target version: {{VERSION}}  (ask the user for this if not provided)

Tasks:
1. Validate version bump in build files (versionCode/CFBundleVersion must be incremented)
2. Run release checklist:
   - No TODO(release) or FIXME comments
   - No debug code in release config
   - ProGuard/R8 enabled (Android) / Dead code stripping (iOS)
   - No hardcoded strings outside resource files
3. Generate user-facing release notes (Play Store: max 500 chars, App Store: max 4000 chars)
4. Output build commands:
   Android: ./gradlew bundleRelease
   iOS: xcodebuild archive + exportArchive
   Fastlane: bundle exec fastlane deploy_internal

Output: ## Release [VERSION] with Blockers / Checklist / Notes / Commands
```
Tools to allow: Read, Grep, Glob, Bash

---

## SDLC Summary Report

After all stages, print:

```
════════════════════════════════════════════════════════
  SDLC Report — {{FEATURE}}
  Platform: {{PLATFORM}}
════════════════════════════════════════════════════════
  [✓] Stage 1 — PLAN          Architecture: [chosen pattern]
  [✓] Stage 2 — BUILD         Files: [N files created]
  [✓] Stage 3 — TEST          Tests: [N test cases]
  [✗] Stage 4 — REVIEW        Blockers: [list if any]
  [✓] Stage 5 — SECURITY      Findings: [N critical, M high]
  [✓] Stage 6 — ACCESSIBILITY WCAG AA: [pass / N issues fixed]
  [✓] Stage 7 — RELEASE       Version: [X.Y.Z]
════════════════════════════════════════════════════════

Open items:
- [ ] [Any unresolved issues]

Run these to validate:
  Android: ./gradlew lint && ./gradlew test && ./gradlew bundleRelease
  iOS: swiftlint && xcodebuild test -scheme MyApp
```

---

## Variables

- `{{FEATURE}}` = the argument passed to this command
- `{{PLATFORM}}` = ask the user if not obvious from context (android / ios / both)
- `{{PLAN_OUTPUT}}` = output from Stage 1 agent (first 3000 chars)
- `{{BUILD_OUTPUT}}` = output from Stage 2 agent (first 3000 chars)
- `{{VERSION}}` = ask the user at Stage 7
