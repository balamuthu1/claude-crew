---
name: sdlc
description: >
  Slash command: /sdlc
  Runs a full SDLC workflow for a mobile feature — from architecture design
  through implementation, testing, code review, security audit, accessibility
  check, and release preparation. Each stage uses the appropriate specialist agent.
  Usage: /sdlc <feature description>
---

# Mobile SDLC Workflow

Run each stage in sequence. At each gate, confirm with the user before proceeding to the next.

## Stage 1 — PLAN (mobile-architect)

Invoke `mobile-architect` agent.

Ask:
- What is the feature?
- Android, iOS, or both?
- What layers are affected (network, local storage, UI, background work)?

Produce:
- Architecture recommendation (pattern choice + rationale)
- Module/file structure skeleton
- Layer breakdown: Domain → Data → Presentation
- Estimated complexity (S/M/L)

**Gate**: User confirms the architecture before any code is written.

---

## Stage 2 — BUILD (android-feature or ios-feature skill)

Based on confirmed architecture, follow `skills/android-feature.md` or `skills/ios-feature.md`.

Implement in this strict order:
1. Domain models + repository interface + use case
2. Data layer: DTO, API service, repository implementation
3. ViewModel + UiState
4. UI (Compose or SwiftUI)
5. DI wiring
6. Navigation hookup

After each sub-step, confirm the code compiles conceptually before moving on.

**Gate**: All layers implemented.

---

## Stage 3 — TEST (mobile-test-planner)

Invoke `mobile-test-planner` agent using `skills/mobile-test.md`.

Generate:
- Unit tests for ViewModel (all state transitions)
- Unit tests for UseCase (business rules)
- Integration test for Repository (success + error paths)
- UI test for the main happy path
- Edge case matrix: empty, error, offline, large data

**Gate**: Test plan + generated test code confirmed.

---

## Stage 4 — CODE REVIEW (android-reviewer or ios-reviewer)

Invoke the platform-appropriate reviewer agent.

Review all files written in Stage 2 against:
- `rules/kotlin.md` or `rules/swift.md`
- `rules/android-architecture.md` or `rules/ios-architecture.md`

Produce structured review: Critical → Major → Minor.

**Gate**: All Critical and Major issues resolved.

---

## Stage 5 — SECURITY (mobile-security)

Invoke `mobile-security` agent.

Audit the feature code specifically for:
- Data storage (is sensitive data encrypted?)
- Network calls (HTTPS, cert pinning, error handling)
- Input validation (are external inputs sanitized?)
- Authentication (are protected routes guarded?)

Flag any OWASP Mobile Top 10 issues with code-level fixes.

**Gate**: No Critical security issues open.

---

## Stage 6 — ACCESSIBILITY (ui-accessibility)

Invoke `ui-accessibility` agent using `skills/accessibility-audit.md`.

Audit all new UI files for:
- Content descriptions / accessibility labels on interactive elements
- Touch target sizes (≥ 48dp / 44pt)
- Color contrast (4.5:1 ratio for text)
- Reading order and focus order
- Dynamic text / font scaling

**Gate**: No Critical a11y issues. Major issues tracked.

---

## Stage 7 — RELEASE (release-manager)

Invoke `release-manager` agent using `skills/mobile-release.md`.

Steps:
1. Validate version bump (versionCode/CFBundleVersion incremented)
2. Run full release checklist
3. Generate user-facing release notes
4. Output Fastlane commands or manual build steps

---

## SDLC Summary Output

At the end of all stages, produce:

```
## SDLC Completion Report — [Feature Name]

### Platform: [Android / iOS / Both]

### Stages Completed
[✓] Plan       — Architecture: [chosen pattern]
[✓] Build      — Files: [list of created files]
[✓] Test       — Coverage: [layers tested]
[✓] Review     — Issues resolved: [N critical, M major]
[✓] Security   — OWASP findings: [clean / N resolved]
[✓] A11y       — WCAG AA: [pass / N issues fixed]
[✓] Release    — Version: [X.Y.Z], Build: [N]

### Open Items
- [ ] [Any remaining minor issues]

### Commands to Run
# Android
./gradlew lint && ./gradlew test && ./gradlew bundleRelease

# iOS
swiftlint && xcodebuild test -scheme MyApp && xcodebuild archive ...
```
