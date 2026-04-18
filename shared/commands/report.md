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

- No argument → report last **30 days**
- Numeric argument (e.g. `/report 7`) → report last N days
- `--save` flag → also write report to `reports/claude-kpi-<date>.md`
- `all` → report all time (no date filter)

---

## Step 2 — Run the report-agent

Spawn `report-agent` with:

```
Generate a Claude Crew KPI report.
KPI events file: .claude/kpi/events.jsonl
Memory file:     .claude/memory/MEMORY.md
Audit log:       .claude/audit.log
Days to include: <N>  (or "all")
Save to file:    <true/false>
```

Wait for the report output and display it directly.

---

## Step 3 — Team sharing notice

After displaying the report, if `.claude/kpi/events.jsonl` exists but is gitignored, show:

```
──────────────────────────────────────────────────────────
ℹ  For team-wide reporting: commit .claude/kpi/ to git so
   all developers' sessions contribute to the same report.

   Add to .gitignore:
     !.claude/kpi/
     !.claude/kpi/events.jsonl
──────────────────────────────────────────────────────────
```
