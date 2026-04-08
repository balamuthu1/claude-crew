# Claude Crew — Mobile Agent Harness

A Claude Code agent harness purpose-built for **Android & iOS mobile teams**. Provides specialized subagents, skills, hooks, and coding rules that turn Claude Code into a mobile-aware pair programmer and team assistant.

Inspired by [everything-claude-code](https://github.com/affaan-m/everything-claude-code).

---

## What's Inside

```
claude-crew/
├── CLAUDE.md                    # Master instructions for Claude
├── .claude/
│   └── settings.json            # Claude Code config & hooks
├── agents/                      # Specialized subagents
│   ├── android-reviewer.md      # Kotlin/Android code review
│   ├── ios-reviewer.md          # Swift/iOS code review
│   ├── mobile-architect.md      # Architecture advisor
│   ├── mobile-performance.md    # Performance analyzer
│   ├── mobile-security.md       # Security reviewer
│   ├── mobile-test-planner.md   # Test planning
│   ├── release-manager.md       # Release workflow
│   └── ui-accessibility.md      # Accessibility auditor
├── skills/                      # Reusable Claude Code workflows
│   ├── android-feature.md       # Android feature development
│   ├── ios-feature.md           # iOS feature development
│   ├── mobile-code-review.md    # Cross-platform review
│   ├── mobile-test.md           # Mobile testing workflow
│   ├── mobile-release.md        # Release preparation
│   ├── accessibility-audit.md   # Accessibility audit
│   └── performance-profile.md   # Performance profiling
├── hooks/                       # Shell hooks (lifecycle automation)
│   ├── pre-tool-use.sh          # Validation before tool execution
│   └── post-tool-use.sh         # Automation after tool execution
├── rules/                       # Language & architecture standards
│   ├── kotlin.md                # Kotlin coding standards
│   ├── swift.md                 # Swift coding standards
│   ├── android-architecture.md  # Android architecture patterns
│   └── ios-architecture.md      # iOS architecture patterns
└── commands/                    # Slash command definitions
    ├── android-review.md        # /android-review
    ├── ios-review.md            # /ios-review
    ├── mobile-test.md           # /mobile-test
    └── mobile-release.md        # /mobile-release
```

---

## How the Harness Works

```
Your Mobile Project
│
├── CLAUDE.md          ← Claude Code reads this AUTOMATICALLY every session
│                        Sets behavior rules, agent routing, language standards
│
├── .claude/
│   ├── settings.json  ← Claude Code reads this AUTOMATICALLY
│   │                    Wires hooks, sets permissions
│   │
│   ├── hooks/         ← Shell scripts Claude Code EXECUTES at lifecycle events
│   │   ├── pre-tool-use.sh   (blocks dangerous ops before they run)
│   │   └── post-tool-use.sh  (reminds to lint/test after edits)
│   │
│   └── commands/      ← Claude Code exposes these as /slash-commands
│       ├── sdlc.md          → /sdlc
│       ├── android-review.md → /android-review
│       └── ...
│
├── agents/            ← Specialist knowledge bases (loaded on demand)
│   └── *.md             Invoked via @mention or by CLAUDE.md routing rules
│
├── rules/             ← Coding standards loaded by agents and CLAUDE.md
└── skills/            ← Step-by-step workflow guides used by commands
```

**What's automated vs manual:**

| Mechanism | When | Trigger |
|---|---|---|
| `CLAUDE.md` | Every session | Automatic |
| `settings.json` | Every session | Automatic |
| Hooks | On tool use | Automatic |
| Slash commands | On demand | You type `/sdlc` |
| Agents | On demand | You type `@android-reviewer` or CLAUDE.md routes |
| Skills | On demand | Referenced by commands and agents |

---

## SDLC Workflow

Run a full feature lifecycle in one session:

```
/sdlc Build a user profile editing screen for Android
```

This runs 7 stages sequentially, each with a human gate:

```
Stage 1 — PLAN        @mobile-architect   → architecture decision
Stage 2 — BUILD       /android-feature    → domain → data → VM → UI
Stage 3 — TEST        @mobile-test-planner → unit + UI + edge cases
Stage 4 — REVIEW      @android-reviewer   → code quality gate
Stage 5 — SECURITY    @mobile-security    → OWASP audit
Stage 6 — A11Y        @ui-accessibility   → WCAG 2.1 AA check
Stage 7 — RELEASE     @release-manager    → version bump + release notes
```

You can also run any single stage independently:

```bash
/android-review          # just review the code
/mobile-test             # just generate tests
/mobile-release 2.5.0    # just prep the release
@mobile-security         # just the security audit
```

---

## Quick Start

### 1. Copy into your mobile project

```bash
cp -r claude-crew/.claude your-mobile-project/.claude
cp -r claude-crew/agents  your-mobile-project/.claude/agents
cp -r claude-crew/skills  your-mobile-project/.claude/skills
cp claude-crew/CLAUDE.md  your-mobile-project/CLAUDE.md
```

### 2. Use slash commands

| Command | What it does |
|---|---|
| `/android-review` | Review Android/Kotlin code for quality, patterns, perf |
| `/ios-review` | Review Swift/iOS code for quality, patterns, perf |
| `/mobile-test` | Generate a full test plan for a feature |
| `/mobile-release` | Walk through release checklist |

### 3. Invoke specialized agents

```
@android-reviewer Review this ViewModel for MVVM correctness
@ios-reviewer Check this SwiftUI view for memory leaks
@mobile-architect Suggest the right architecture for offline-first sync
@mobile-security Audit this API client for certificate pinning issues
@release-manager Prepare the release notes for v2.4.0
```

---

## Agents at a Glance

| Agent | Specialty |
|---|---|
| `android-reviewer` | Kotlin idioms, Jetpack, Coroutines, Compose |
| `ios-reviewer` | Swift best practices, SwiftUI, Combine, UIKit |
| `mobile-architect` | Clean Architecture, MVVM, MVI, offline-first |
| `mobile-performance` | ANR/freeze detection, memory, battery, render perf |
| `mobile-security` | OWASP Mobile Top 10, cert pinning, data storage |
| `mobile-test-planner` | Unit, UI, integration, snapshot test strategy |
| `release-manager` | App Store / Play Store release workflows |
| `ui-accessibility` | WCAG mobile, TalkBack, VoiceOver, contrast |

---

## Hooks

Hooks run automatically via Claude Code's lifecycle:

- **PreToolUse** — validates destructive operations before they run
- **PostToolUse** — reminds about lint/test after file edits

Configure in `.claude/settings.json`.

---

## Platform Support

| Platform | Language | Architecture |
|---|---|---|
| Android | Kotlin (primary), Java (legacy) | MVVM + Clean, MVI |
| iOS | Swift (primary), Obj-C (legacy) | MVVM + Clean, VIPER, TCA |
| Cross-platform | React Native / Flutter | To be extended |
