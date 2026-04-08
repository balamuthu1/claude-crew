Facilitate a sprint retrospective for the mobile engineering team.

Accepts an optional format argument: `/retro` (default: Start/Stop/Continue) or `/retro sailboat` or `/retro 4ls`.

Run the following steps directly — do not spawn a sub-agent.

---

## Step 0 — Load context

Read `jira.config.md` if it exists. Extract `project-key`, `board-id`, sprint naming config.

```bash
command -v jira && jira me 2>/dev/null || echo "NOT_READY"
```

Detect the format from the command argument (default: `ssc` = Start/Stop/Continue):
- `sailboat` or `boat` → Sailboat format
- `4ls` or `4l` → 4Ls format
- `mad-sad-glad` or `msg` → Mad/Sad/Glad format
- anything else → Start/Stop/Continue

---

## Step 1 — Review previous retro actions

Ask:
```
Before we collect new feedback — did we follow through on last retro's actions?

List any action items from your previous retro, or type "skip" to continue.
```

If actions are provided, go through each one:
```
Action: [description]   Owner: @person   Status?
Options: ✅ Done | 🔄 In Progress | ❌ Not started | 🗑 No longer relevant
```

Print a quick scorecard:
```
Previous retro actions: 3 done ✅, 1 in progress 🔄, 1 not started ❌
```

Flag if the same action item appears from a prior retro — it's a recurring problem.

---

## Step 2 — Pull sprint context from Jira

```bash
jira issue list --project {key} --sprint active --status Done --no-headers 2>/dev/null
jira sprint list --project {key} --state active --no-headers 2>/dev/null | head -1
```

Use this to open the retro with concrete numbers:
```
## Retrospective — {sprint-name}

Sprint summary:
  Committed: {N} pts  |  Delivered: {M} pts  |  Carry-over: {K} pts
  Completed stories: {list}
  Carry-over stories: {list}

Let's reflect on how the sprint went.
```

If Jira is unavailable, ask the user for sprint summary numbers.

---

## Step 3 — Collect feedback

### Format: Start / Stop / Continue (default)

Ask each category separately. Wait for responses before moving on.

```
## ▶ START
What should we START doing that we're not doing now?
(Things that would improve our flow, quality, collaboration, or wellbeing)

Share your ideas — one per message is fine, or list them all at once.
Type "done" when you're finished with this category.
```

```
## ⏹ STOP
What should we STOP doing?
(Things that slow us down, create waste, or cause frustration)
```

```
## ✅ CONTINUE
What should we CONTINUE doing?
(Things working well that we want to protect)
```

### Format: Sailboat

```
## ⛵ SAILBOAT RETROSPECTIVE

🌬️  WIND — What accelerated us this sprint?
⚓  ANCHORS — What held us back or slowed us down?
🪨  ROCKS — What risks or obstacles lie ahead?
☀️  SUN (Goal) — What's our north star for next sprint?
```

### Format: 4Ls

```
## 4Ls RETROSPECTIVE

😊  LIKED — What did you enjoy or appreciate this sprint?
🧠  LEARNED — What did you discover or understand better?
😕  LACKED — What was missing that would have helped?
💭  LONGED FOR — What do you wish had been different?
```

### Format: Mad / Sad / Glad

```
## MAD / SAD / GLAD

😡  MAD — What frustrated or angered you?
😢  SAD — What disappointed you?
😊  GLAD — What made you happy or proud?
```

---

## Step 4 — Dot voting (if many items)

If more than 8 items were raised across categories, run a dot vote:

```
We have {N} items. Let's prioritise. Each person gets 3 votes.
React with a number (1, 2, 3...) for the items you care most about.

{numbered list of all items}

Share your votes: e.g. "1, 1, 4" to put 2 votes on item 1 and 1 vote on item 4.
```

Sort by votes and take the top 5 for action planning.

---

## Step 5 — Define action items

For each top theme, guide the team to a concrete action:

```
## Action Items

For each issue you want to address, define:
  Action: [specific, observable change — not "communicate better"]
  Owner:  [@person responsible]
  Due:    [next sprint / specific date]

Tip: "We'll hold a 30-min async channel for questions" beats "improve communication".
```

For each confirmed action item, offer to create a Jira task:
```
Create a Jira task for: "{action}"? [Y/n]
```

If yes:
```bash
jira issue create \
  --project {key} \
  --type Task \
  --summary "Retro action: {action}" \
  --assignee "{owner}"
```

---

## Step 6 — Print retro summary

```
## Retrospective Summary — {sprint-name}   {date}

### What went well ✅
- {item}
- {item}

### What to improve 🔧
- {item}
- {item}

### Action Items
| # | Action                          | Owner  | Due           | Jira    |
|---|---------------------------------|--------|---------------|---------|
| 1 | {action}                        | @alice | Next sprint   | PROJ-N  |
| 2 | {action}                        | @bob   | 14 Apr        | PROJ-M  |

Previous actions score: {X}/{Y} completed.
```

---

## Step 7 — Close

```
Retro complete. Great work reflecting honestly — that's how teams get better.

Reminder: review these action items at the START of next retro.
Any final thoughts before we close?
```
