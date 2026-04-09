# Claude Crew — Project Memory
#
# This file is read automatically at the start of every session.
# It accumulates learnings across all sessions so the harness becomes
# more accurate and project-aware over time.
#
# Written by: session-end hook, learning-agent, reviewer agents, and /learn command.
# Curated by: /memory-review (periodic housekeeping).
# Committed to git: YES — shared across the whole team.
#
# Entry format:
#   [YYYY-MM-DD | confidence:high/medium/low | source:who-wrote-this]
#   Content of the learning — be specific and actionable.
#
# confidence:high   → validated multiple times, used as a hard rule by agents
# confidence:medium → observed but not fully confirmed, used as a suggestion
# confidence:low    → extracted automatically, needs human validation
#
# To promote an entry: change confidence:low → medium → high
# To remove an entry: delete the line
# To correct an entry: edit inline — agents will use the updated version

---

## Architecture & Stack

<!-- Agents write here when they discover how the project is built.
     detect-arch auto-populates this section. -->

<!-- EXAMPLE (delete when real entries exist):
[2025-04-09 | confidence:high | source:detect-arch]
  DI: Hilt. Never suggest Koin — team migrated away deliberately.

[2025-04-09 | confidence:high | source:detect-arch]
  UI: Jetpack Compose only. No XML layouts in new code.
-->

---

## Naming & Code Conventions

<!-- Agents write here when they notice consistent naming patterns.
     Reviewer agents write here when they find naming violations. -->

<!-- EXAMPLE:
[2025-04-09 | confidence:high | source:android-reviewer]
  Composable screens must end in "Screen" (LoginScreen, not LoginView or LoginPage).

[2025-04-09 | confidence:medium | source:session-end]
  ViewModels are in a flat `presentation/` package, not sub-packaged by feature.
-->

---

## Patterns & Best Practices

<!-- Agents write here when they identify project-specific patterns to follow. -->

<!-- EXAMPLE:
[2025-04-09 | confidence:high | source:android-reviewer]
  All network calls must go through a Result<T> wrapper — never throw exceptions to the UI.

[2025-04-09 | confidence:high | source:ios-reviewer]
  Use @MainActor on all ViewModel @Published properties — discovered thread violation in PROJ-88.
-->

---

## Antipatterns & Known Issues

<!-- Agents write here when they find patterns the team must AVOID.
     Security findings always go here. -->

<!-- EXAMPLE:
[2025-04-09 | confidence:high | source:mobile-security]
  runBlocking in ViewModels caused ANR on low-end devices (see PROJ-42). Never use it.

[2025-04-09 | confidence:high | source:android-reviewer]
  SharedPreferences used for auth tokens in legacy code — do NOT copy this pattern.
  Use EncryptedSharedPreferences for all new token storage.
-->

---

## Team Preferences & Corrections

<!-- Written by session-end hook when it detects the user correcting Claude's output.
     Also written by explicit /learn calls. -->

<!-- EXAMPLE:
[2025-04-09 | confidence:high | source:explicit-learn]
  Team prefers exhaustive `when` expressions over if/else chains for sealed classes.

[2025-04-09 | confidence:medium | source:session-end]
  User corrected: use `collectAsStateWithLifecycle()` not `collectAsState()` for Flow.
-->

---

## Git & Branching

<!-- git-flow-advisor writes here when it detects actual patterns in use. -->

<!-- EXAMPLE:
[2025-04-09 | confidence:high | source:detect-gitflow]
  Branch pattern confirmed: feature/PROJ-{id}-{kebab-description}
  Example from repo: feature/PROJ-123-add-biometric-login
-->

---

## Jira & Sprint

<!-- jira-advisor and scrum-master write here. -->

<!-- EXAMPLE:
[2025-04-09 | confidence:high | source:jira-advisor]
  Actual sprint velocity over last 3 sprints: 18pts, 22pts, 16pts. Average: 18.7pts.

[2025-04-09 | confidence:medium | source:scrum-master]
  Team uses "In Testing" not "QA" as the pre-done status (custom workflow).
-->

---

## Security Notes

<!-- mobile-security and /security-scan write here. -->

<!-- EXAMPLE:
[2025-04-09 | confidence:high | source:mobile-security]
  No certificate pinning implemented. PROJ-200 tracks adding it — do not generate
  code that assumes pinning exists.
-->

---

## Build & CI

<!-- Written when build commands, CI patterns, or tooling is discovered. -->

<!-- EXAMPLE:
[2025-04-09 | confidence:high | source:session-end]
  Build command: ./gradlew assembleDebug (not just build — assembleRelease requires signing config)
  Test command: ./gradlew testDebugUnitTest
-->
