---
description: Toggle teach mode on/off for the session. When active, every workflow explains each phase, quizzes you, and generates a final learning report. Usage: /teach-mode [on|off|status]
---

Run directly — do not spawn a sub-agent.

## What teach mode does

When active, **every command you run** (`/sdlc`, `/android-review`, `/security-scan`, etc.) becomes an interactive learning session:

- Before each phase executes → Claude explains the phase (what it is, why it matters, how it works)
- After the explanation → 2–3 quiz questions tailored to that specific phase and context
- After your answers → scoring + feedback + running total
- After all phases → full session report: per-phase scores, weak spots, recommended next steps

Questions are generated dynamically from the actual context — if you're reviewing a `UserViewModel`, the quiz will be about ViewModel patterns, not generic theory.

---

## Step 1 — Detect action

Check the user's argument:
- `on` or no argument → **enable** teach mode (go to Step 2a)
- `off` → **disable** teach mode (go to Step 2b)
- `status` → **show** current state (go to Step 2c)
- `report` → **show** accumulated session scores from `.claude/TEACH_MODE.md` (go to Step 2d)

---

## Step 2a — Enable teach mode

Write `.claude/TEACH_MODE.md` using the Write tool:

```markdown
# Claude Crew — Teach Mode

status: active
enabled_at: <current datetime>

---

## Session Log

(Phase scores will be appended here as you run workflows)

| Timestamp | Workflow | Phase | Score | Total |
|-----------|----------|-------|-------|-------|
```

Then confirm to the user:

```
✓ Teach mode is ON

Every workflow you run will now pause before each phase to:
  1. Explain what the phase does and why it matters
  2. Quiz you with 2–3 contextual questions
  3. Score and give feedback on your answers
  4. Then execute the phase as normal
  5. Generate a full learning report at the end

Try it now — run any command:
  /sdlc Build a user profile screen
  /android-review
  /security-scan

Turn off anytime: /teach-mode off
Check scores:     /teach-mode report
```

---

## Step 2b — Disable teach mode

Overwrite `.claude/TEACH_MODE.md` with:

```markdown
# Claude Crew — Teach Mode

status: inactive
disabled_at: <current datetime>
```

Confirm:

```
✓ Teach mode is OFF — all workflows running normally.

Your session scores are still in .claude/TEACH_MODE.md if you want to review them.
```

---

## Step 2c — Status

Read `.claude/TEACH_MODE.md`. Then:

**If file doesn't exist or status is `inactive`:**
```
  Teach mode: OFF
  Enable with: /teach-mode on
```

**If status is `active`:**
```
  Teach mode: ON (enabled at <time>)
  All workflows are running in teach mode.
  Turn off:     /teach-mode off
  View scores:  /teach-mode report
```

---

## Step 2d — Report

Read `.claude/TEACH_MODE.md` and display the session log table. If it's empty:

```
  No scores recorded yet. Run a workflow in teach mode to start.
```

Otherwise, show the table and compute an overall average score.
