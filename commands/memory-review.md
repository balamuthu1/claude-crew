---
description: Review and curate accumulated project memory. Promotes low-confidence entries, removes stale ones, and shows a confidence summary.
---

Invoke the `learning-agent` to run an interactive memory review.

Pass it the following context:
- Mode: `memory-review`
- Memory file: `memory/MEMORY.md`
- Today's date: use `date +"%Y-%m-%d"` to get it

The agent will:
1. Read `memory/MEMORY.md` and group all entries by confidence level
2. For each `confidence:low` entry: ask whether to promote to medium, delete, edit, or skip
3. For `confidence:medium` entries older than 30 days: ask whether to promote to high, keep, or delete
4. Print a summary: Promoted N / Deleted N / Kept N, and total counts per confidence level

Use this command periodically (weekly or after a major sprint) to keep the memory file accurate and clean.
