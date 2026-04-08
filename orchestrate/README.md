# Mobile SDLC Orchestrator

Runs the full mobile feature lifecycle by spawning **specialist Claude sub-agents**
via the [Claude Agent SDK](https://github.com/anthropics/claude-agent-sdk-python).

---

## How It Works (vs. the markdown harness)

```
Without orchestration (current harness):
  Claude Code reads CLAUDE.md → one model, one context window,
  role-plays through all SDLC stages sequentially.

With orchestration (this script):
  ┌─────────────────────────────────────────────────┐
  │   sdlc_runner.py  (orchestrator process)        │
  │                                                 │
  │  Stage 1 ──► spawn architect sub-agent          │
  │               └─ isolated context, Opus 4.6     │
  │  Stage 2 ──► spawn android/ios reviewer         │
  │               └─ isolated context, Sonnet 4.6   │
  │  Stage 3 ──► spawn test-planner sub-agent       │
  │  Stage 4 ──► spawn code-reviewer sub-agent      │
  │                                                 │
  │  Stages 5+6 run CONCURRENTLY:                   │
  │  ├──► spawn security sub-agent   ─┐             │
  │  └──► spawn accessibility agent  ─┘ asyncio     │
  │                                                 │
  │  Stage 7 ──► spawn release-manager sub-agent    │
  └─────────────────────────────────────────────────┘
```

Key differences:
- **Isolated context**: each sub-agent starts fresh, focused on its domain
- **Parallel audit**: security + accessibility run simultaneously (saves ~50% time)
- **Cost control**: architecture/security use Opus; review/test use Sonnet
- **Context passing**: previous stage output is summarized and passed as input to next stage
- **CI mode**: `--no-interactive` for automated pipelines

---

## Setup

```bash
pip install -r requirements.txt
# Requires ANTHROPIC_API_KEY in environment
```

---

## Usage

```bash
# Full SDLC for an Android feature
python sdlc_runner.py "Build a user profile editing screen" --platform android

# iOS only, skip release prep
python sdlc_runner.py "Add push notifications" --platform ios --skip release

# Just plan + build (fast, for scaffolding)
python sdlc_runner.py "Implement offline cart" --stages plan,build

# CI mode — no prompts, save report
python sdlc_runner.py "Refactor payment flow" \
  --no-interactive \
  --output reports/payment-sdlc.md

# Quick/cheap run with Haiku
python sdlc_runner.py "Fix login bug" --model claude-haiku-4-5 --stages review,security
```

---

## Stage → Agent Mapping

| Stage | Agent | Model | Parallel? |
|---|---|---|---|
| plan | `architect` | Opus 4.6 | No |
| build | `android` / `ios` | Sonnet 4.6 | No |
| test | `test` | Sonnet 4.6 | No |
| review | `android` / `ios` | Sonnet 4.6 | No |
| security | `security` | Opus 4.6 | **Yes** |
| accessibility | `accessibility` | Sonnet 4.6 | **Yes** |
| release | `release` | Sonnet 4.6 | No |

---

## CI Integration (GitHub Actions example)

```yaml
- name: Run mobile SDLC
  env:
    ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
  run: |
    pip install -r orchestrate/requirements.txt
    python orchestrate/sdlc_runner.py \
      "PR: ${{ github.event.pull_request.title }}" \
      --platform android \
      --stages review,security,accessibility \
      --no-interactive \
      --output sdlc-report.md

- name: Upload SDLC report
  uses: actions/upload-artifact@v4
  with:
    name: sdlc-report
    path: sdlc-report.md
```

---

## Architecture Decision

This orchestrator uses the **Claude Agent SDK** (`claude-agent-sdk` Python package)
rather than the raw Anthropic API because:

1. Each sub-agent needs **file access** (Read, Grep, Glob) to inspect the codebase
2. Sub-agents may need **multiple turns** (read file → analyze → read another file)
3. The Agent SDK provides built-in tools, lifecycle management, and the `Agent` tool
   for sub-agent spawning — no need to re-implement the tool loop

The alternative (raw `anthropic` SDK + manual tool loop) would require wiring up
file-access tools manually and managing the agentic loop per stage — 200+ lines
that the Agent SDK handles for free.
