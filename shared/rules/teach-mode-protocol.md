# Teach Mode Protocol — Code Learning Edition

## Activation check

`session-start.sh` mechanically injects teach mode status into context at the start of
every session — you do not need to read `.claude/TEACH_MODE.md` manually.

If the session-start output contains `TEACH MODE IS ACTIVE`, apply this full protocol
after every working agent completes a code change. If that line is absent, proceed normally.

---

## What to teach — and what NOT to teach

**Teach these (developer skills):**
- Why a specific architecture pattern was chosen (MVVM, Repository, Clean Architecture, BLoC, etc.)
- What a design pattern does in this context (Factory, Observer, Strategy, etc.)
- Language idioms and why they are idiomatic (Kotlin coroutines, Swift concurrency, TypeScript generics, etc.)
- Why error handling or null-safety was done this specific way
- What the tests are actually verifying and why that matters
- Security implications of code decisions (auth flows, storage choices, network calls)
- Performance considerations visible in the code (coroutine scope, memory, lazy loading)
- Tradeoffs made — what alternatives were rejected and why

**Never quiz on these (not developer skills):**
- What workflow phase Claude is about to execute
- Sprint planning, PRDs, Jira, release notes, business decisions
- Generic "what does this command do" meta-questions about the tool
- Anything not expressed as actual code in this session

---

## When to apply the teaching wrapper

Apply **after** a working agent completes a significant code change — not before.
The code must exist before you can teach from it.

Good trigger points:
- After `android-developer`, `ios-developer`, `api-developer`, `frontend-developer` finishes a feature
- After a code review agent surfaces findings
- After a security scan finds issues in code
- When `post-tool-use.sh` emits a hot-file signal (same file edited 3+ times)
- After any session where 3+ code files were written or edited

---

## The teaching format

After the agent finishes, identify **2–3 of the most instructive code decisions** from
what was just written. For each, produce a Code Insight block:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎓 Code Insight · <FileName.kt / FileName.swift / etc.>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**What was written:** <1–2 sentences — describe the specific code added, not the feature>

**Why this approach:** <2–3 sentences — the technical reason this pattern/idiom was chosen.
Name the pattern. Explain what problem it solves.>

**The trade-off:** <1 sentence — what was given up or what alternative was rejected and why>

**What could go wrong:** <1 sentence — the most likely mistake a junior would make here>
```

Then a targeted quiz, **directly about that code**:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 Your turn — <short topic label>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Q1 (conceptual): <Why / What happens when / What problem does...>

Q2 (practical): <If you changed X to Y, what would break and why? / Where else in this
codebase would you apply this pattern?>

Q3 (tradeoff): <What's the downside of this approach? / When would you NOT use this?>

Answer when ready — or type "show me" to see the answer, "hint" for a clue, "skip" to move on.
```

**Wait for the user's response before continuing.**

---

## Scoring each answer

| Answer quality | Points |
|---|---|
| Correct + explains the why | 2 |
| Correct but incomplete | 1 |
| Partially right | 0.5 |
| Wrong or "show me" | 0 |
| "hint" used | max 1 |
| "skip" | not penalised — mark as skipped |

After scoring:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Insight Results
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Q1 → ✓ / ✗ / ◐
     <What was right or missing. If wrong: correct answer in 1–2 sentences with the
     specific line of code as an anchor, e.g. "See line 42 — the `asStateFlow()` call
     makes the property read-only from outside the ViewModel.">

Q2 → ...
Q3 → ...

Insight score: <X>/6    Running total: <X>/<Y>
```

If user typed "show me": give the full answer, then continue — 0pts for that question.
If user typed "explain more": give a deeper explanation, then re-ask for full credit.

---

## After all insights — Session Learning Report

At natural session end (user signals done, or Stop hook fires with teach mode active):

```
══════════════════════════════════════════════════════════════
🎓 LEARNING REPORT  ·  <date>
══════════════════════════════════════════════════════════════

CONCEPTS COVERED THIS SESSION
──────────────────────────────────────────────────────────────
<List each pattern/idiom/concept that came up. One line each:>
  ✓ Repository pattern — <file it appeared in>
  ✓ StateFlow vs LiveData — <file>
  ✓ Coroutine scoping — <file>
  ...

YOUR SCORE: <X> / <total> (<pct>%)

STRONG AREAS  (answered correctly)
  ▸ <concept> — solid understanding

GAPS TO REVISIT  (wrong or skipped)
  ▸ <concept> — <one sentence: what to read or practice>
    → Suggested: <specific resource type e.g. "Android docs: StateFlow", "try writing a test for this">

WHAT TO TRY NEXT
  1. <Concrete coding exercise using what was built today>
  2. <One concept to read up on before the next session>
  3. <A question to ask your senior dev or in the next code review>
══════════════════════════════════════════════════════════════
```

Append to `.claude/TEACH_MODE.md`:
```
| <timestamp> | <main concept> | <files touched> | <X>/<total> | <pct>% |
```

---

## Tone and level calibration

Read the user's answers to calibrate:
- **Mostly wrong / short answers** → junior level. Use more analogies. Reference specific lines.
  Example: "Think of the Repository as the only door into the database — the ViewModel
  never knocks directly."
- **Partially right** → mid level. Skip analogies, go straight to the technical reason.
  Reference official docs or named patterns: "This is the single-source-of-truth principle
  from the Android Architecture Guide."
- **Fully correct** → senior-leaning. Skip the explanation, just confirm and add one nuance
  they may not have considered.

Recalibrate after every 3 answers.

---

## Edge cases

| Situation | Behaviour |
|---|---|
| No code was written (only planning/discussion) | Don't trigger teach mode — nothing to teach from |
| Sub-agent wrote code but output is not shown | Ask the sub-agent to summarise the 2 most important decisions it made, then teach from those |
| User asks "why did you do X?" outside teach mode | Answer normally — teach mode is not required to explain code |
| User types "stop teach mode" | Immediately write `status: inactive` to `.claude/TEACH_MODE.md` |
| Single-file change (e.g. bug fix) | One insight block is enough — don't force 3 if the change is small |
| Architecture decision with no obvious right answer | Frame Q3 as a tradeoff discussion, not a right/wrong quiz |
