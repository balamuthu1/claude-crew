# Teach Mode Protocol

## Activation

At the very start of executing ANY workflow, slash command, or multi-phase task:

1. Use the Read tool to check if `.claude/TEACH_MODE.md` exists and contains `status: active`.
2. If teach mode is **active**, apply this protocol to every phase/step before executing it.
3. If teach mode is **inactive or absent**, proceed normally — no change in behaviour.

## Apply this wrapper around each distinct phase or step

### Before the phase executes — TEACH

Display a teaching block:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎓 TEACH MODE  ·  Phase <N>: <Phase Name>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📖 What this phase does:
<2–3 sentences explaining the purpose of this phase in the workflow>

💡 Why it matters:
<1–2 sentences on the business or technical value>

🔍 What's about to happen:
<Concrete description of what Claude will do in this specific invocation — mention actual file names, feature names, or context from the user's request>
```

### Quiz — 2–3 contextual questions

Generate 2–3 questions **specific to this phase and the current context**. Mix types:
- At least one conceptual question ("Why does...?", "What is the purpose of...?")
- At least one practical question ("In this project, where would you...?", "What's wrong with...?")
- Optionally one multiple-choice for precision

Format:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 Quick Quiz — Phase <N>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Q1: <question>

Q2: <question>
  a) ...
  b) ...
  c) ...
  d) ...

Q3: <question>

Answer all three — take your time. Type "skip" to skip this quiz, "hint" for a clue.
```

**Wait for the user's reply before proceeding.**

### After the user answers — SCORE

Evaluate each answer. Award: **1pt** correct, **0.5pt** partial, **0pt** incorrect.

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Phase <N> Results
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Q1 → ✓ Correct   / ✗ Incorrect / ◐ Partial
     <One sentence: what was right, what was missing, correct answer if wrong>

Q2 → ✓ / ✗ / ◐
     <feedback>

Q3 → ✓ / ✗ / ◐
     <feedback>

Phase score: <X> / 3   Running total: <X> / <Y>
```

If the user typed "hint": give a clue but cap that question at 0.5pt max.
If the user typed "skip": record phase as skipped (not penalised), proceed immediately.

Then **execute the phase** and proceed to the next one.

### After all phases — FINAL REPORT

```
══════════════════════════════════════════════════════
🎓 TEACH MODE — SESSION REPORT
   Workflow: <workflow name>   Date: <today>
══════════════════════════════════════════════════════

OVERALL SCORE: <X> / <total> (<pct>%)

  ≥ 90%  🏆 Excellent — strong mastery of this workflow
  75–89% 👍 Good — a few gaps worth revisiting
  60–74% 📚 Fair — review weak phases before using in production
  < 60%  🔄 Needs work — go through the weak phases again

──────────────────────────────────────────────────────
PHASE BREAKDOWN
──────────────────────────────────────────────────────
  <phase name> ............ <X>/3  (<pct>%)  [Strong / Review / Redo / Skipped]
  ...

──────────────────────────────────────────────────────
TOPICS TO REVISIT
──────────────────────────────────────────────────────
<List only phases scored < 70%. For each:>
  ▸ <Phase> — <one-sentence summary of the gap>
    Tip: <specific reading or follow-up command>

<If all phases ≥ 70%:>
  🎉 No weak spots. You're ready to use this workflow confidently.

──────────────────────────────────────────────────────
NEXT STEPS
──────────────────────────────────────────────────────
  1. Try it for real: <suggest a concrete next command>
  2. <Targeted tip based on lowest-scoring phase>
  3. Run another workflow in teach mode: /teach-mode status

══════════════════════════════════════════════════════
```

Then append a row to `.claude/TEACH_MODE.md`'s Session Log table:
```
| <timestamp> | <workflow> | all phases | <X>/<total> | <pct>% |
```

## Edge cases

| Situation | Behaviour |
|---|---|
| User types "skip" | Skip the quiz for this phase — not penalised |
| User types "hint" | Give a hint, cap that question at 0.5pt |
| User types "explain more" after wrong answer | Deeper explanation, offer to re-ask for full credit |
| User types "stop teach mode" | Immediately disable: overwrite `.claude/TEACH_MODE.md` with `status: inactive` |
| Single-step command (no distinct phases) | Treat the whole command as one phase |
| Sub-agent spawned by workflow | The sub-agent does NOT run teach mode — only the orchestrating conversation does |
