# Claude Crew — Mobile Agent Harness

A **Claude Code plugin** for Android & iOS mobile engineering teams. Installs 13 specialist agents, 12 slash commands, 10 workflow skills, lifecycle hooks, and coding rules — all adapting to your project's actual architecture, git conventions, Jira workflow, and Scrum process.

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
/detect-arch       ← auto-detect your mobile stack
/detect-gitflow    ← auto-detect your git branching conventions
/detect-jira       ← connect and configure your Jira project
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

### 1. Architecture config

After installing, run `/detect-arch` inside your mobile project. It reads your build files (`build.gradle.kts`, `libs.versions.toml`, `Package.swift`, `Podfile`) and writes `claude-crew.config.md`:

```
/detect-arch
```

All agents read `claude-crew.config.md` before doing anything — so they review against **your** architecture, not an opinionated default:

```yaml
platform: android
pattern: mvvm
ui: compose
state: coroutines-flow
di: hilt
networking: retrofit
storage: room
```

If your project uses Dagger2, the reviewer won't flag it as wrong. If you use RxJava, it won't suggest migrating to Flow.

### 2. Git flow config

Run `/detect-gitflow` to teach Claude your team's branching model, commit style, and sprint workflow:

```
/detect-gitflow
```

This starts an interactive Q&A, inspects your git history for defaults, and writes `git-flow.config.md`. After this, the `git-flow-advisor` can:

- Generate correct branch names for any ticket
- Format commit messages in your team's style
- Guide sprint starts, hotfix flows, and release cuts
- Write PR titles and descriptions in your format

### 3. Jira config

Run `/detect-jira` to connect Claude to your Jira board (requires [Jira CLI](https://github.com/ankitpokhrel/jira-cli)):

```bash
# Install Jira CLI first
brew install ankitpokhrel/jira-cli/jira-cli
jira init

# Then in Claude Code:
/detect-jira
```

This asks about your project key, board, issue types, workflow statuses, sprint setup, and linking conventions, then writes `jira.config.md`. After this, the `jira-advisor` can:

- Show your current sprint board
- Create tickets from feature descriptions
- Transition issues through your workflow
- Break epics into Android + iOS stories
- Link branches and PRs to Jira tickets

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

### Slash commands

| Command | What it does |
|---|---|
| `/sdlc <feature>` | Full 7-stage SDLC pipeline |
| `/android-review` | Android/Kotlin code review |
| `/ios-review` | Swift/iOS code review |
| `/mobile-test <file>` | Generate test suite |
| `/mobile-release <version>` | Release preparation checklist |
| `/detect-arch` | Auto-detect project architecture → `claude-crew.config.md` |
| `/detect-gitflow` | Interactive git conventions setup → `git-flow.config.md` |
| `/sprint-start [N]` | Kick off a sprint: sync branches, create sprint branch, print checklist |
| `/detect-jira` | Interactive Jira project setup → `jira.config.md` |
| `/standup` | Facilitate today's daily standup with live Jira board |
| `/retro [format]` | Run a sprint retrospective (Start/Stop/Continue, Sailboat, 4Ls) |
| `/sprint-health` | Check burndown, surface at-risk stories, forecast carry-over |

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
@git-flow-advisor    Name a branch for PROJ-42 adding dark mode
@jira-advisor        Show my sprint board / create a story / move PROJ-123 to In Review
@scrum-master        Run standup / check sprint health / facilitate retro / coach on DoD
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
| `git-flow-advisor` | Branch names, commit messages, PR titles, sprint/hotfix/release workflow | Read, Bash, Glob, Grep |
| `jira-advisor` | Sprint board, ticket creation, issue transitions, epic breakdown | Read, Bash, Glob, Grep |
| `scrum-master` | Sprint planning, standup, retro, health checks, velocity, Agile coaching | Read, Bash, Glob, Grep |

---

## Skills

Structured workflows invokable as skills:

| Skill | What it covers |
|---|---|
| `android-feature` | Build a new Android feature end-to-end |
| `ios-feature` | Build a new iOS feature end-to-end |
| `mobile-test` | Generate a test suite for a feature or file |
| `mobile-release` | Walk through the release checklist |
| `mobile-code-review` | Cross-platform code review workflow |
| `accessibility-audit` | Full WCAG 2.1 AA audit workflow |
| `performance-profile` | Performance analysis workflow |
| `git-flow` | Git branching, commit, sprint, hotfix, and release reference |
| `jira-flow` | Jira CLI quick reference, daily workflow, sprint planning |
| `scrum` | Ceremonies, DoD/DoR, story points, velocity, anti-patterns quick reference |

---

## Plugin structure

```
claude-crew/
├── .claude-plugin/
│   ├── plugin.json          ← plugin manifest
│   └── marketplace.json     ← self-hosted marketplace definition
│
├── agents/                  ← 12 specialist agents
│   ├── android-developer.md
│   ├── ios-developer.md
│   ├── android-reviewer.md
│   ├── ios-reviewer.md
│   ├── mobile-architect.md
│   ├── mobile-security.md
│   ├── mobile-performance.md
│   ├── mobile-test-planner.md
│   ├── ui-accessibility.md
│   ├── release-manager.md
│   ├── git-flow-advisor.md
│   ├── jira-advisor.md
│   └── scrum-master.md
│
├── commands/                ← 12 slash commands
│   ├── sdlc.md
│   ├── android-review.md
│   ├── ios-review.md
│   ├── mobile-test.md
│   ├── mobile-release.md
│   ├── detect-arch.md
│   ├── detect-gitflow.md
│   ├── sprint-start.md
│   ├── detect-jira.md
│   ├── standup.md
│   ├── retro.md
│   └── sprint-health.md
│
├── skills/                  ← 10 skills, each in <name>/SKILL.md
│   ├── android-feature/SKILL.md
│   ├── ios-feature/SKILL.md
│   ├── mobile-test/SKILL.md
│   ├── mobile-release/SKILL.md
│   ├── mobile-code-review/SKILL.md
│   ├── accessibility-audit/SKILL.md
│   ├── performance-profile/SKILL.md
│   ├── git-flow/SKILL.md
│   ├── jira-flow/SKILL.md
│   └── scrum/SKILL.md
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
├── rules/                   ← coding standards and process rules (installed to project)
│   ├── kotlin.md
│   ├── swift.md
│   ├── android-architecture.md
│   ├── ios-architecture.md
│   └── scrum.md
│
├── claude-crew.config.md    ← project architecture config template
├── git-flow.config.md       ← git conventions config template
├── jira.config.md           ← Jira project config template
├── CLAUDE.md                ← orchestration rules and agent dispatch table
├── install.sh               ← manual installer
└── uninstall.sh             ← clean uninstaller
```

---

## How it works

Claude Code natively discovers plugin content from the standard directories. No Python, no external dependencies — just markdown files and bash scripts that Claude Code reads natively.

The `/sdlc` command instructs Claude to use the built-in `Agent` tool to spawn isolated sub-agents. Each agent gets its own context window with a focused system prompt, preventing context bleed between stages.

All agents read their relevant config files at the start of every task:
- `claude-crew.config.md` — mobile stack (DI, UI, state, networking)
- `git-flow.config.md` — branching model, commit style, sprint workflow
- `jira.config.md` — project key, board, workflow statuses, sprint setup

---

## Platform support

| Platform | Languages | Patterns |
|---|---|---|
| Android | Kotlin, Java (legacy) | MVVM, MVI, Clean Architecture |
| iOS | Swift, Obj-C (legacy) | MVVM, TCA, Clean Architecture |

---

## License

MIT
