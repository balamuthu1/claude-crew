---
description: Toggle coding teach mode on/off. When active, every code change becomes a learning moment — explains patterns and architecture decisions, quizzes on the actual code written, and builds a session learning report. Designed for junior and mid-level developers learning alongside Claude.
---

Run directly — do not spawn a sub-agent.

## What teach mode does

When active, **after every significant code change**, Claude pauses to teach from the real code:

- **Code Insight** — explains what pattern or idiom was just used, why it was chosen, what trade-off was made, and what could go wrong
- **Targeted quiz** — 3 questions about the actual code written (not workflow theory), calibrated to your level based on your answers
- **Session report** — lists every concept covered, your strong areas, gaps to revisit, and what to try next

Questions are about the **code in front of you**, not about process or planning:
> "Why is `_authState` private but `authState` public?" → not → "What does this workflow phase do?"

Works seamlessly alongside any coding command: `/sdlc`, `/android-review`, `/security-scan`, or plain coding requests.

---

## Step 1 — Detect action

- `on` or no argument → **enable** (Step 2a)
- `off` → **disable** (Step 2b)
- `status` → **show current state** (Step 2c)
- `report` → **show session scores** (Step 2d)

---

## Step 2a — Enable

Write `.claude/TEACH_MODE.md`:

```markdown
# Claude Crew — Teach Mode

status: active
enabled_at: <current datetime>
level: auto  <!-- calibrated from your answers — starts neutral -->

---

## Session Log

| Timestamp | Concept | Files | Score | Total |
|-----------|---------|-------|-------|-------|
```

Confirm to the user:

```
✓ Teach mode is ON — coding education mode active

After every significant code change I'll:
  1. Explain the key pattern or architecture decision in plain terms
  2. Ask you 3 questions about the actual code (not workflow theory)
  3. Score your answers and give feedback referencing specific lines
  4. Calibrate difficulty to your level as we go

At the end of the session I'll generate a report: concepts covered,
strong areas, gaps to revisit, and what to practice next.

Start coding — try any of these:
  /sdlc Build a login screen with token refresh
  /android-review
  Or just describe what you want to build

Turn off: /teach-mode off   ·   View report: /teach-mode report
```

---

## Step 2b — Disable

Write `status: inactive` to `.claude/TEACH_MODE.md`. Confirm:

```
✓ Teach mode is OFF

Your session log is still in .claude/TEACH_MODE.md — run /teach-mode report to review it.
```

---

## Step 2c — Status

Read `.claude/TEACH_MODE.md`.

**If inactive or absent:**
```
  Teach mode: OFF
  Enable: /teach-mode on
```

**If active:**
```
  Teach mode: ON  (since <time>)
  Level calibrated to: <junior / mid / auto>

  Recent concepts covered:
  <last 3 entries from Session Log, or "none yet">

  Turn off: /teach-mode off  ·  Full report: /teach-mode report
```

---

## Step 2d — Report

Read `.claude/TEACH_MODE.md`. Display the session log table.

If empty: `No concepts logged yet — run a coding workflow with teach mode on.`

Otherwise show the table and compute:
- Overall score average
- Most frequently seen concept categories
- Suggested next learning focus
