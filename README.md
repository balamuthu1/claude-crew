# Claude Crew — Mobile Agent Harness

A Claude Code plugin for **Android & iOS mobile teams**. Installs 8 specialist agents,
5 slash commands, lifecycle hooks, and coding rules in one script.

Inspired by [everything-claude-code](https://github.com/affaan-m/everything-claude-code).

---

## Install

### Global — agents available in every project

```bash
curl -sSL https://raw.githubusercontent.com/balamuthu1/claude-crew/main/install.sh | bash -s -- --global
```

### Project — scoped to one repo

```bash
# From your mobile project root:
curl -sSL https://raw.githubusercontent.com/balamuthu1/claude-crew/main/install.sh | bash
```

### Local clone

```bash
git clone https://github.com/balamuthu1/claude-crew.git
cd claude-crew

./install.sh --global            # global install
./install.sh                     # project install (current dir)
./install.sh --project ~/MyApp   # project install (specific dir)
./install.sh --dry-run           # preview without changing anything
```

### Uninstall

```bash
./uninstall.sh           # remove from current project
./uninstall.sh --global  # remove global install
```

---

## What Gets Installed

```
~/.claude/  (global)  OR  your-project/.claude/  (project)
│
├── agents/                  ← 8 specialist agents (auto-discovered by Claude Code)
│   ├── android-reviewer.md       Kotlin/Compose/Jetpack review
│   ├── ios-reviewer.md           Swift/SwiftUI/Combine review
│   ├── mobile-architect.md       Architecture decisions
│   ├── mobile-performance.md     ANR, memory, battery, jank
│   ├── mobile-security.md        OWASP Mobile Top 10
│   ├── mobile-test-planner.md    Test strategy + code gen
│   ├── release-manager.md        App Store / Play Store
│   └── ui-accessibility.md       WCAG 2.1 AA audit
│
├── commands/                ← Slash commands (/sdlc, /android-review, …)
│   ├── sdlc.md                   Full 7-stage SDLC orchestrator
│   ├── android-review.md         /android-review
│   ├── ios-review.md             /ios-review
│   ├── mobile-test.md            /mobile-test
│   └── mobile-release.md         /mobile-release
│
├── hooks/                   ← Lifecycle automation
│   ├── pre-tool-use.sh           Guards destructive ops, keystore files, secrets
│   └── post-tool-use.sh          Reminds to lint/test after edits
│
└── settings.json            ← Merged with any existing config

CLAUDE.md                    ← Appended to project CLAUDE.md (or ~/.claude/CLAUDE.md)
rules/                       ← Kotlin, Swift, Android arch, iOS arch standards
skills/                      ← Workflow guides (android-feature, ios-feature, …)
```

---

## Usage

### Full SDLC in one command

```
/sdlc Build a user profile editing screen for Android
```

Spawns 7 specialist sub-agents — each with an **isolated context window**:

```
Stage 1 — PLAN         → mobile-architect    architecture decision
Stage 2 — BUILD        → android/ios agent   domain → data → VM → UI
Stage 3 — TEST         → test-planner        unit + UI + edge cases
Stage 4 — REVIEW       → code reviewer       quality gate
Stage 5 — SECURITY  ┐  → security auditor    OWASP Mobile Top 10   ← parallel
Stage 6 — A11Y      ┘  → a11y auditor        WCAG 2.1 AA           ← parallel
Stage 7 — RELEASE      → release manager     version + release notes
```

Stages 5 & 6 run **in parallel** — two `Agent` tool calls in one message.

### Individual commands

```
/android-review      Review Android/Kotlin code
/ios-review          Review Swift/iOS code
/mobile-test         Generate test suite for a feature or file
/mobile-release 2.5  Release preparation checklist
```

### Mention agents directly

```
@android-reviewer   Review this ViewModel for MVVM correctness
@ios-reviewer       Check this SwiftUI view for memory leaks
@mobile-architect   Design offline-first cart sync
@mobile-security    Audit this API client for cert pinning
@ui-accessibility   Check touch targets and VoiceOver labels
```

---

## How It Works

Claude Code natively supports:

| File/Dir | Loaded | Purpose |
|---|---|---|
| `CLAUDE.md` | Every session, automatic | Behavior rules, agent routing |
| `.claude/settings.json` | Every session, automatic | Hooks, permissions |
| `.claude/agents/*.md` | On demand via Agent tool | Specialist sub-agents |
| `.claude/commands/*.md` | On demand via `/command` | Slash commands |
| `.claude/hooks/*.sh` | On tool use, automatic | Lifecycle scripts |

The `/sdlc` command is a **pure Claude Code orchestrator** — it instructs Claude
to use the built-in `Agent` tool to spawn isolated sub-agents. No Python, no external
dependencies. The harness is just markdown files that Claude Code reads natively.

---

## Agents

| Agent | Specialty |
|---|---|
| `android-reviewer` | Kotlin idioms, Jetpack, Coroutines, Compose |
| `ios-reviewer` | Swift, SwiftUI, Combine, UIKit, async/await |
| `mobile-architect` | Clean Architecture, MVVM, MVI, TCA, offline-first |
| `mobile-performance` | ANR, memory leaks, battery, render jank |
| `mobile-security` | OWASP Mobile Top 10, cert pinning, data storage |
| `mobile-test-planner` | Unit, integration, UI, snapshot test strategy |
| `release-manager` | App Store / Play Store workflows, Fastlane |
| `ui-accessibility` | WCAG 2.1 AA, TalkBack, VoiceOver, contrast |

---

## Platform Support

| Platform | Language | Architecture |
|---|---|---|
| Android | Kotlin (primary), Java (legacy) | MVVM + Clean Architecture, MVI |
| iOS | Swift (primary), Obj-C (legacy) | MVVM + Clean Architecture, TCA |
| Cross-platform | React Native / Flutter | Extensible |

---

## Optional: CI Orchestrator (Python)

For automated pipelines without Claude Code CLI, the `orchestrate/` directory
contains a Python script using the `claude-agent-sdk` that runs the same SDLC
workflow headlessly:

```bash
pip install -r orchestrate/requirements.txt
python orchestrate/sdlc_runner.py "feature description" --platform android --no-interactive
```

---

## License

MIT
