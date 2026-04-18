---
description: Extract high-confidence project memory into reusable skill files. Run after several sessions to promote validated patterns into .claude/skills/ so every agent loads them automatically.
---

Invoke the `skill-extractor` agent to promote accumulated project knowledge into reusable skills.

Pass it the following context:
- Memory file: `.claude/memory/MEMORY.md`
- Skills directory: `.claude/skills/`
- Today's date: use `date +"%Y-%m-%d"` to get it

## What this does

`/evolve` reads all `confidence:high` entries in project memory and groups them by domain.
When a domain has 3 or more validated rules, it writes (or updates) a skill file at
`.claude/skills/<domain>-learned/SKILL.md`.

These skill files are loaded automatically by Claude Code when relevant — no further
configuration needed. Every agent that works in this project will apply the learned rules.

## When to run

- After the first few weeks of a project (once enough memory has been validated)
- After a `/memory-review` session that promoted several entries to `confidence:high`
- When you notice agents repeating the same project-specific reminders every session

## Confidence ladder reminder

Memory entries move up automatically through sessions:
- `confidence:low` — auto-captured, needs human review via `/memory-review`
- `confidence:medium` — seen twice, promoted automatically
- `confidence:high` — seen three or more times, or explicitly promoted by `/learn`

Only `confidence:high` entries become skills. Run `/memory-review` first if you want to
accelerate promotion of entries you've already validated.
