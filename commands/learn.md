---
description: Explicitly teach Claude something new about this project. Written to .claude/memory/MEMORY.md with confidence:high so it applies to all future sessions.
---

Invoke the `learning-agent` to capture an explicit learning.

Pass it the following context:
- Mode: `explicit-learn`
- Content to learn: $ARGUMENTS
- Today's date: use `date +"%Y-%m-%d"` to get it
- Memory file: `.claude/memory/MEMORY.md`

The agent will:
1. Read `.claude/memory/MEMORY.md` to check for duplicates
2. Determine the correct section (Architecture, Naming, Patterns, Antipatterns, Team Preferences, Git, Jira, Security, Build)
3. Write the entry with `confidence:high` and `source:explicit-learn`
4. Confirm what was written and where

If no content is provided in $ARGUMENTS, ask: "What would you like me to remember about this project?"
