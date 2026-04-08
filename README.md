# Claude Crew — Mobile Agent Harness

A **Claude Code plugin** for Android & iOS mobile engineering teams. Installs 10 specialist agents, 6 slash commands, 7 workflow skills, lifecycle hooks, and coding rules — all adapting to your project's actual architecture.

---

## Installation

### Option 1 — Claude Code Plugin (recommended)

The fastest way. Works directly inside Claude Code without cloning anything.

```
/plugin marketplace add balamuthu1/claude-crew
/plugin install claude-crew@claude-crew
```

Then set up your project config:

```
/detect-arch
```

### Option 2 — Manual script

```bash
git clone https://github.com/balamuthu1/claude-crew.git
bash claude-crew/install.sh --global           # available in every project
bash claude-crew/install.sh                    # current project only
bash claude-crew/install.sh --project ~/MyApp  # specific project
bash claude-crew/install.sh --dry-run          # preview without changes
```

### Uninstall

```bash
bash claude-crew/uninstall.sh           # remove from current project
bash claude-crew/uninstall.sh --global  # remove global install
```

---

## First-time setup

After installing, run `/detect-arch` inside your mobile project. It reads your build files (`build.gradle.kts`, `libs.versions.toml`, `Package.swift`, `Podfile`) and writes a `claude-crew.config.md` that tells every agent what your project actually uses:

```
/detect-arch
```

All 10 agents read `claude-crew.config.md` before doing anything — so they review against **your** architecture, not an opinionated default:

```yaml
platform: android
pattern: mvvm
ui: compose
state: coroutines-flow
di: hilt
networking: retrofit
storage: room
...
```

If your project uses Dagger2, the reviewer won't flag it as wrong. If you use RxJava, it won't suggest migrating to Flow. Edit the file manually if the detector misses anything.

---

## Usage

### Full SDLC in one command

```
/sdlc Build a user profile editing screen for Android
```

Spawns 7 specialist sub-agents, each with an **isolated context window**:

```
Stage 1 — PLAN         → mobile-architect     architecture decision
Stage 2 — BUILD        → android-developer    domain → data → VM → UI → DI
Stage 3 — TEST         → mobile-test-planner  unit + integration + UI tests
Stage 4 — REVIEW       → android-reviewer     quality gate
Stage 5 — SECURITY  ┐  → mobile-security      OWASP Mobile Top 10   ← parallel
Stage 6 — A11Y      ┘  → ui-accessibility     WCAG 2.1 AA           ← parallel
Stage 7 — RELEASE      → release-manager      version bump + release notes
```

Stages 5 & 6 run **in parallel** — two Agent tool calls in one message.

### Slash commands

| Command | What it does |
|---|---|
| `/sdlc <feature>` | Full 7-stage SDLC pipeline |
| `/android-review` | Android/Kotlin code review |
| `/ios-review` | Swift/iOS code review |
| `/mobile-test <file>` | Generate test suite |
| `/mobile-release <version>` | Release preparation checklist |
| `/detect-arch` | Auto-detect project architecture |

### Mention agents directly

```
@android-developer   Implement a dark mode toggle for Android
@ios-developer       Build the profile screen in SwiftUI
@android-reviewer    Review this ViewModel for MVVM correctness
@ios-reviewer        Check this SwiftUI view for memory leaks
@mobile-architect    Design offline-first cart sync
@mobile-security     Audit this API client for cert pinning
@ui-accessibility    Check touch targets and VoiceOver labels
@mobile-performance  Why is this list scrolling janky?
```

---

## Agents

| Agent | Role | Tools |
|---|---|---|
| `android-developer` | Writes production Kotlin/Compose code end-to-end | Read, Write, Edit, Glob, Grep, Bash |
| `ios-developer` | Writes production Swift/SwiftUI code end-to-end | Read, Write, Edit, Glob, Grep, Bash |
| `android-reviewer` | Reviews Kotlin, Jetpack, Coroutines, Compose | Read, Grep, Glob |
| `ios-reviewer` | Reviews Swift, SwiftUI, Combine, UIKit, async/await | Read, Grep, Glob |
| `mobile-architect` | Clean Architecture, MVVM, MVI, TCA, offline-first | Read, Grep, Glob |
| `mobile-security` | OWASP Mobile Top 10, cert pinning, data storage | Read, Grep, Glob |
| `mobile-performance` | ANR, memory leaks, battery drain, render jank | Read, Grep, Glob |
| `mobile-test-planner` | Unit, integration, UI, snapshot test generation | Read, Write, Edit, Glob |
| `ui-accessibility` | WCAG 2.1 AA, TalkBack, VoiceOver, contrast | Read, Grep, Glob |
| `release-manager` | App Store / Play Store, versioning, Fastlane | Read, Grep, Glob, Bash |

---

## Skills

Structured workflows invokable as skills:

| Skill | Trigger |
|---|---|
| `android-feature` | Build a new Android feature end-to-end |
| `ios-feature` | Build a new iOS feature end-to-end |
| `mobile-test` | Generate a test suite for a feature or file |
| `mobile-release` | Walk through the release checklist |
| `mobile-code-review` | Cross-platform code review workflow |
| `accessibility-audit` | Full WCAG 2.1 AA audit workflow |
| `performance-profile` | Performance analysis workflow |

---

## Plugin structure

```
claude-crew/
├── .claude-plugin/
│   ├── plugin.json          ← plugin manifest
│   └── marketplace.json     ← self-hosted marketplace definition
│
├── agents/                  ← 10 specialist agents
│   ├── android-developer.md
│   ├── ios-developer.md
│   ├── android-reviewer.md
│   ├── ios-reviewer.md
│   ├── mobile-architect.md
│   ├── mobile-security.md
│   ├── mobile-performance.md
│   ├── mobile-test-planner.md
│   ├── ui-accessibility.md
│   └── release-manager.md
│
├── commands/                ← 6 slash commands
│   ├── sdlc.md
│   ├── android-review.md
│   ├── ios-review.md
│   ├── mobile-test.md
│   ├── mobile-release.md
│   └── detect-arch.md
│
├── skills/                  ← 7 skills, each in <name>/SKILL.md
│   ├── android-feature/SKILL.md
│   ├── ios-feature/SKILL.md
│   ├── mobile-test/SKILL.md
│   ├── mobile-release/SKILL.md
│   ├── mobile-code-review/SKILL.md
│   ├── accessibility-audit/SKILL.md
│   └── performance-profile/SKILL.md
│
├── scripts/                 ← lifecycle hook scripts
│   ├── pre-tool-use.sh      guards destructive ops, keystores, secrets
│   └── post-tool-use.sh     reminds lint/test after edits, scans for secrets
│
├── hooks/
│   └── hooks.json           ← hook config (for plugin install path)
│
├── settings.json            ← permissions + hooks (for manual install path)
│
├── rules/                   ← coding standards (installed to project)
│   ├── kotlin.md
│   ├── swift.md
│   ├── android-architecture.md
│   └── ios-architecture.md
│
├── claude-crew.config.md    ← project architecture config template
├── CLAUDE.md                ← orchestration rules and agent dispatch table
├── install.sh               ← manual installer
└── uninstall.sh             ← clean uninstaller
```

---

## How it works

Claude Code natively discovers plugin content from the standard directories. No Python, no external dependencies — just markdown files and bash scripts that Claude Code reads natively.

The `/sdlc` command instructs Claude to use the built-in `Agent` tool to spawn isolated sub-agents. Each agent gets its own context window with a focused system prompt, preventing context bleed between stages.

All agents read `claude-crew.config.md` at the start of every task so they adapt their rules to your project's actual stack — not an assumed default.

---

## Platform support

| Platform | Languages | Patterns |
|---|---|---|
| Android | Kotlin, Java (legacy) | MVVM, MVI, Clean Architecture |
| iOS | Swift, Obj-C (legacy) | MVVM, TCA, Clean Architecture |

---

## License

MIT
