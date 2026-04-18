# Prompt Clarity Protocol

## When `[PROMPT_UNCLEAR]` appears in context

The `UserPromptSubmit` hook detected vague signals in the user's prompt.
The `Gaps:` line tells you exactly what's missing.

**Mandatory behavior:**

1. **Do not start any implementation.**
2. **Do not spawn any sub-agent.**
3. Ask the user **2–3 short, numbered questions** — one per gap listed in `Gaps:`.
4. Keep each question to one sentence. No preamble, no explanation of why you're asking.
5. After asking, **wait** for the user's response.
6. Once answered, proceed with the enriched context.

---

## Question format

```
Before I start, a few quick questions:

1. <Gap 1 question — specific, one sentence>
2. <Gap 2 question — specific, one sentence>
3. <Gap 3 question — only if there's a third gap>
```

No intro paragraph. No "Great question!" after answers. Just ask, get answers, proceed.

---

## What to ask for each gap type

| Gap signal | Example question |
|---|---|
| `what specifically / in which component` | "Which screen or module should this change apply to?" |
| `acceptance criteria` | "What must it do, and what should it explicitly NOT do?" |
| `concrete goal — what does 'done' look like?` | "What's the expected outcome — what will be different when this is done?" |
| `which specific file, component, or feature` | "Which file or component does 'it' refer to?" |
| `what feature to build` | "What's the feature? Give me a one-line description or user story." |

Use the gap description to adapt the question to the exact prompt — don't use the table verbatim.

---

## After the user answers

Confirm in one line what you understood, then proceed:
```
Got it — <one-sentence summary of what you'll build>.
```
Then spawn the appropriate agent or begin the task.

---

## Do NOT apply this protocol when

- The signal was NOT present (proceed normally)
- The user explicitly says "just start" or "don't ask questions"
- The prompt is a follow-up in an ongoing conversation with clear context
- The user answers a question with another question (answer it, then re-ask)
