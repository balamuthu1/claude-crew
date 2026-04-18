---
description: Generate a Claude adoption and KPI report for leadership. Shows session activity, success rates, security findings caught, knowledge growth, and teach mode engagement. Optionally scoped to last N days.
---

Run directly — do not spawn a sub-agent.

## What this command does

Reads `.claude/kpi/events.jsonl` and other Claude Crew data files, then computes and displays
a leadership-ready KPI report showing how Claude is being used, where it adds value, and where
adoption could improve.

---

## Step 1 — Parse arguments

- No argument → individual report, last **30 days**
- Numeric argument (e.g. `/report 7`) → individual report, last N days
- `--team` → aggregate all developers' event files (`events-*.jsonl`)
- `--team 7` → team report scoped to last 7 days
- `--save` → also write report to `reports/claude-kpi-<date>.md`
- `all` → no date filter (all time)

---

## Step 2 — Run the report-agent

Spawn `report-agent` with:

```
Generate a Claude Crew KPI report.
KPI events directory: .claude/kpi/
Memory file:          .claude/memory/MEMORY.md
Audit log:            .claude/audit.log
Days to include:      <N>  (or "all")
Team mode:            <true/false>
Save to file:         <true/false>
```

Wait for the report output and display it directly.

---

## Step 3 — Team sharing notice (individual mode only)

After displaying an individual report, check whether other developers' event files
exist in `.claude/kpi/`. If they do and `--team` was not used, show:

```
──────────────────────────────────────────────────────────
ℹ  <N> other developer(s) have KPI data in .claude/kpi/
   Run /report --team for the full team view.
──────────────────────────────────────────────────────────
```

If no `events-*.jsonl` files exist at all (fresh install), show:

```
──────────────────────────────────────────────────────────
ℹ  For team-wide reporting, each developer must commit
   their .claude/kpi/events-<name>.jsonl file to git.
   install.sh already added the gitignore exceptions.
──────────────────────────────────────────────────────────
```
