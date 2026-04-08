Facilitate today's daily standup for the mobile engineering team.

Run the following steps directly — do not spawn a sub-agent.

---

## Step 0 — Load context

Read `jira.config.md` and `git-flow.config.md` if they exist. Extract:
- `project-key`, `board-id`, `sprint-name-pattern`, `status-in-progress`, `status-in-review`, `status-done`

Check Jira CLI:
```bash
command -v jira && jira me 2>/dev/null || echo "NOT_READY"
```

---

## Step 1 — Pull today's sprint board

```bash
jira issue list \
  --project {project-key} \
  --sprint active \
  --order-by status \
  --no-headers 2>/dev/null
```

Also get today's date and the sprint name:
```bash
date "+%a %d %b %Y"
jira sprint list --project {project-key} --state active --no-headers 2>/dev/null | head -1
```

If Jira CLI is unavailable, skip the board pull and continue with the standup format only.

---

## Step 2 — Open the standup

Print:
```
## Daily Standup — {day} {date}
Sprint: {sprint-name}

Current board snapshot:
  {ticket}  [{status}]  {summary}  → {assignee}
  ...

Let's go around. For each person, share:
  ✅ Done since last standup
  🔨 Doing until next standup
  🚧 Blockers or risks (or "none")

Who's going first?
```

---

## Step 3 — Collect updates

For each team member who shares an update, record:
- Their name
- Done items (with ticket IDs if mentioned)
- Doing items (with ticket IDs if mentioned)
- Blockers / risks (classify as BLOCKER, RISK, or DEPENDENCY)

If a ticket ID is mentioned that doesn't match the board, note it.
If a blocker is raised, immediately ask:
```
Who will own resolving this, and by when?
```

Continue until the user signals everyone has gone (e.g., "that's everyone" or "done").

---

## Step 4 — Print standup summary

```
## Standup Summary — {date}

| Person  | Done                        | Doing                    | Blockers       |
|---------|-----------------------------|--------------------------|----------------|
| @alice  | PROJ-123 Android impl       | Unit tests               | None           |
| @bob    | PROJ-124 UI review          | Fixes from review        | RISK: see below|

🚧 Blockers & Risks:
  [RISK]       PROJ-124 — API contract unclear. Owner: @bob. Action: sync with backend today.
  [DEPENDENCY] PROJ-126 — waiting on design assets. Owner: @carol. Deadline: EOD tomorrow.
```

---

## Step 5 — Sprint burndown check

Calculate from Jira data:
```
Done:        {X} pts
In Progress: {Y} pts
To Do:       {Z} pts
Total:       {X+Y+Z} pts committed

Sprint day {D} of {total_days}
Expected progress at this point: ~{expected}%
Actual progress (Done / Total):   {actual}%
```

Signal:
- `✅ On track` — actual ≥ expected − 10%
- `⚠️  Slightly behind` — actual is 10–25% below expected
- `🔴 At risk` — actual is >25% below expected

If at risk, suggest:
```
The sprint is at risk. Consider discussing with the PO:
  - Descope: remove {lowest-priority story} ({N} pts) to reduce load
  - Replan: move {story} to next sprint if it has no dependencies this sprint
```

---

## Step 6 — Transition tickets if requested

If a team member mentioned completing a ticket, offer to transition it:
```
@alice mentioned PROJ-123 is done. Move it to "{status-in-review}"? [Y/n]
```

If confirmed:
```bash
jira issue move {ticket} "{status}"
```

---

## Step 7 — Close

Print:
```
Standup done in {duration}. Good luck today! 🚀

Next standup: tomorrow at the same time.
Any blockers not listed above? Reply now or tag me anytime.
```
