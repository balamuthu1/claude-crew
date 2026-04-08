Check the current sprint's health: burndown, risks, blockers, and carry-over forecast.

Run the following steps directly — do not spawn a sub-agent.

---

## Step 0 — Load context

Read `jira.config.md` if it exists. Extract:
- `project-key`, `board-id`, `sprint-duration`, `sprint-start-day`
- `status-in-progress`, `status-in-review`, `status-in-qa`, `status-done`, `status-ready`
- `story-points-field`

Check Jira CLI:
```bash
command -v jira && jira me 2>/dev/null || echo "NOT_READY"
```

If CLI is unavailable, ask the user for sprint data manually:
```
Jira CLI is not available. Please share:
  1. Sprint name and start/end dates
  2. Total points committed
  3. Points completed so far
  4. Any stories blocked or not started yet
```

---

## Step 1 — Fetch sprint data

```bash
# Active sprint info
jira sprint list --project {key} --state active --no-headers 2>/dev/null | head -3

# All issues in the sprint with status and points
jira issue list \
  --project {key} \
  --sprint active \
  --order-by status \
  --no-headers 2>/dev/null
```

Also get today's date to calculate sprint day number:
```bash
date "+%Y-%m-%d"
```

---

## Step 2 — Calculate health metrics

From the data, compute:

**Burndown:**
```
total_points    = sum of all story points in sprint
done_points     = sum of points with status = {status-done}
in_progress_pts = sum of points with status = {status-in-progress} or {status-in-review}
todo_points     = sum of points with status = {status-ready}

sprint_day      = today - sprint_start_date (in working days)
sprint_length   = {sprint-duration} in working days (10 for 2-week)
expected_done % = sprint_day / sprint_length × 100
actual_done %   = done_points / total_points × 100
```

**Carry-over risk:**
```
at_risk_points = todo_points + (in_progress_pts × 0.5)
carry_over_risk = at_risk_points / total_points × 100
```

**Stale tickets:**
Any ticket with no status change in the last 3 working days (if detectable from Jira).

---

## Step 3 — Print health report

```
## Sprint Health Check — {sprint-name}
{date}  |  Day {D} of {total_days}

### Burndown
  Committed:   {total_points} pts
  Done:        {done_points} pts  ({actual_done}%)
  In Progress: {in_progress_pts} pts
  To Do:       {todo_points} pts

  Expected progress today: ~{expected_done}%
  Actual progress today:    {actual_done}%
  Status: {✅ On track | ⚠️ Slightly behind | 🔴 At risk}

### Story Breakdown
  ✅ Done ({done_points} pts):
     PROJ-123  Add biometric login        8pts
     PROJ-125  Crash fix iOS login        3pts

  🔨 In Progress / Review ({in_progress_pts} pts):
     PROJ-124  Profile screen redesign    5pts  → @bob (day 3)
     PROJ-127  Dark mode toggle           5pts  → @alice (day 1)

  📋 Not Started ({todo_points} pts):
     PROJ-126  Kotlin 2.0 upgrade         2pts
     PROJ-128  Analytics integration      5pts  ⚠️ large, not started

### Risks
  {list risks or "No risks detected"}

### Blockers
  {list blockers or "No blockers on the board"}
```

---

## Step 4 — Flag specific risks

Check for and flag:

**Behind schedule:**
If actual_done % is >15% below expected:
```
⚠️  Sprint is behind schedule by ~{gap}%.
    At current pace, {N} pts may carry over.
    Consider discussing with PO: descope {story} ({pts} pts)?
```

**Stale tickets:**
Any story unchanged for ≥3 working days:
```
🔴 PROJ-124 has not moved in 3 days (still {status}).
   Ask @bob: is this blocked? Needs help? Should it be split?
```

**Large stories not started past midpoint:**
Any story ≥8 pts still in "To Do" after day 5 of a 10-day sprint:
```
⚠️  PROJ-128 (Analytics, 5pts) not started on Day {D}.
   Risk of carry-over. Assign now or descope.
```

**Too much in-progress simultaneously:**
If in-progress count > (team size × 1.5):
```
⚠️  {N} stories in progress simultaneously for a team of {M}.
   WIP limit exceeded. Finish before starting new work.
```

**P1/P2 bugs in the sprint:**
```
🚨 PROJ-130 is a P1 Bug in this sprint.
   Confirm: is this being tracked separately from the sprint goal?
```

---

## Step 5 — Forecast

```
### Carry-over Forecast

If the team maintains current pace:
  Likely to complete: {done + in_progress_pts} pts
  At risk of carry-over: {todo_points} pts
  Carry-over rate: {carry_over_risk}%

{✅ Healthy — within 20% buffer | ⚠️ Moderate risk | 🔴 High risk — discuss with PO}
```

If carry-over risk >20%, suggest specific actions:
```
Recommended actions:
  1. Descope PROJ-128 ({N}pts) — not started, low dependency
  2. Pair @alice and @bob on PROJ-124 to unblock it
  3. Move PROJ-126 to next sprint — lowest priority, no blockers but no capacity
```

---

## Step 6 — Offer next steps

```
What would you like to do?
  1. Transition a ticket status
  2. Flag a blocker in Jira
  3. See velocity trend (last 3 sprints)
  4. Prepare a sprint health summary to share with the team
  5. Nothing — just wanted the overview
```

Respond to whichever option the user picks.
