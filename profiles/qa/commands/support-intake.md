---
description: Full QA intake for a support team Jira ticket. Classifies severity and priority, investigates the codebase for a fix plan, writes reproduction steps, and posts a structured intake comment on the ticket. Run when the support team escalates a Jira ticket to engineering.
argument: required — Jira ticket ID (e.g. "PROJ-456")
---

Run the full QA intake workflow for the support team ticket passed as argument.

You are the **orchestrator**. Do NOT investigate, classify, or comment on the ticket
yourself — spawn a dedicated sub-agent for each stage using the `Agent` tool.

---

## Before starting

Validate the argument. If no ticket ID was provided, print:
```
Usage: /support-intake <JIRA-ID>
Example: /support-intake PROJ-456
```
Then stop.

Read `workflow.config.md` and `qa.config.md`. Extract:

- `{{TICKET_ID}}` — argument passed to this command
- `{{TICKET_SYSTEM}}` — from workflow.config.md (e.g. Jira)
- `{{JIRA_PROJECT}}` — from workflow.config.md `jira_project_key`
- `{{SEVERITY_LABELS}}` — from qa.config.md (e.g. Critical/High/Medium/Low)

---

## Stage 1 — ENRICH

Spawn `support-intake-specialist`.

Agent prompt:
```
You are the support-intake-specialist enriching an incoming support ticket.

Ticket ID: {{TICKET_ID}}
Ticket system: {{TICKET_SYSTEM}}
Severity labels: {{SEVERITY_LABELS}}

Read workflow.config.md.
Read profiles/qa/agents/support-intake-specialist.md for the classification framework and Jira CLI patterns.

1. Fetch the full ticket: jira issue view {{TICKET_ID}} --plain
2. Classify:
   - Severity: Critical / High / Medium / Low (justify using the framework in your agent file)
   - Priority: P0 / P1 / P2 / P3 (Priority = Severity × Business Impact × User Volume)
   - Component/area: identify which system area the bug is in (or "unknown")
3. Add labels: support-escalation, qa-intake
   jira issue edit {{TICKET_ID}} --label "support-escalation" --label "qa-intake" --no-input
4. Update priority:
   jira issue edit {{TICKET_ID}} --priority <mapped_priority> --no-input
   (Map: P0→Highest, P1→High, P2→Medium, P3→Low)

Output:
SEVERITY: [value]
PRIORITY: [P0/P1/P2/P3]
COMPONENT: [name or unknown]
TICKET_SUMMARY: [copy the ticket title and description, first 1500 chars]

Tools: Bash, Read
```

---

## Stage 2 — INVESTIGATE

Run TWO sub-agents **in parallel**:

### 2a — CODEBASE INVESTIGATION
Spawn `bug-triager`.

Agent prompt:
```
You are the bug-triager investigating a support ticket to find the root cause in the codebase.

Ticket: {{TICKET_ID}}
Summary and description from Stage 1:
{{TICKET_SUMMARY}}

Severity: {{SEVERITY}}
Component area: {{COMPONENT}}

Read profiles/qa/agents/bug-triager.md.
Read profiles/qa/skills/freshservice-triage/SKILL.md (Codebase Investigation Checklist section).

Investigate the codebase:
1. Extract the error message, feature name, or component from the ticket description
2. Grep for the exact error string or relevant function/component name
3. Glob for files in the suspected component directory
4. Read candidate files — find the code path that produces the reported behaviour
5. Form a hypothesis: "This is likely caused by X in path/to/file:N because Y"
6. Rate confidence: High / Medium / Low
7. Suggest a fix: describe what change would resolve it

If you find a fix path, output:
FIX_FOUND
Hypothesis: [description]
Confidence: High | Medium | Low
Candidate files:
  - path/to/file.ts:42 — [why suspicious]
Suggested fix: [1–3 sentence description]

If no code path found after 3–4 search attempts, output:
NO_FIX_FOUND

Tools: Grep, Glob, Read
```

### 2b — REPRODUCTION STEPS
Spawn `bug-triager`.

Agent prompt:
```
You are the bug-triager writing detailed reproduction steps for a support-escalated ticket.

Ticket: {{TICKET_ID}}
Summary and description:
{{TICKET_SUMMARY}}

Severity: {{SEVERITY}}
Component: {{COMPONENT}}

Read profiles/qa/agents/bug-triager.md.

Using the ticket description, write:

1. Preconditions — the exact starting state required (logged in as X, on page Y, with data condition Z)
2. Numbered reproduction steps — each step is a SINGLE action, no compound steps
3. Expected result — what SHOULD happen (precise, not vague)
4. Actual result — what DOES happen (use exact error text from the ticket if present)
5. Reproducibility estimate — Always / Intermittent / Unknown
6. Environment — OS, browser/app version, backend version, feature flags (from ticket or "unknown")

If the ticket lacks enough information to write definitive steps, write the best-effort steps
and flag each uncertain step with "[UNCONFIRMED]".

Output in this format:
REPRO_STEPS:
Preconditions:
- [item]

Steps:
1. [action]
2. [action]
3. [triggering action]

Expected: [description]
Actual: [description]
Reproducibility: Always | Intermittent | Unknown
Environment:
- OS: [value or unknown]
- App/Browser: [value or unknown]
- Backend: [value or unknown]
- Feature flags: [value or none confirmed]

Tools: Read
```

Collect both outputs. Label them `{{INVESTIGATION_RESULT}}` and `{{REPRO_STEPS}}`.

---

## Stage 3 — UPDATE

Spawn `support-intake-specialist`.

Agent prompt:
```
You are the support-intake-specialist posting the final intake comment on a support ticket.

Ticket: {{TICKET_ID}}
Today's date: {{TODAY}}

Classification from Stage 1:
Severity: {{SEVERITY}}
Priority: {{PRIORITY}}
Component: {{COMPONENT}}

Codebase investigation from Stage 2a:
{{INVESTIGATION_RESULT}}

Reproduction steps from Stage 2b:
{{REPRO_STEPS}}

Read profiles/qa/agents/support-intake-specialist.md for the intake comment template and posting pattern.

1. Build the intake comment using the template in your agent file:
   - Fill in all sections: Classification, Reproduction Steps, Fix Plan, Next Steps
   - Fix Plan: use Stage 2a output. If FIX_FOUND, include hypothesis, confidence, candidate files, and suggested fix.
     If NO_FIX_FOUND, write "Root cause not identified in codebase scan — assigned to engineering for investigation."
   - Next Steps: suggest component owner assignment and sprint (P0/P1 → current sprint; P2 → next sprint; P3 → backlog)

2. Post the comment:
   jira issue comment add {{TICKET_ID}} "$(cat <<'COMMENT'
   [comment body here]
   COMMENT
   )"

3. If the investigation found a fix (FIX_FOUND with confidence ≥ Medium), also suggest creating a linked
   sub-task for the fix by printing a ready-to-run command:
   jira issue create --project {{JIRA_PROJECT}} --type Task \
     --summary "Fix: [one-line description from investigation]" \
     --body "Parent: {{TICKET_ID}} ..." --no-input

   Do NOT run this automatically — print it as a suggestion for the QA engineer to approve.

Output: confirmation that the comment was posted, and the sub-task creation suggestion if applicable.

Tools: Bash, Read
```

---

## Summary

After all stages complete, print:

```
════════════════════════════════════════════════════════════
  Support Intake — {{TICKET_ID}} — {{TODAY}}
════════════════════════════════════════════════════════════
  [✓] Stage 1 — ENRICH
      Severity: [value]   Priority: [P0/P1/P2/P3]
      Component: [value]
      Labels added: support-escalation, qa-intake

  [✓] Stage 2 — INVESTIGATE
      Codebase fix: FIX_FOUND (confidence: High/Medium/Low) | NO_FIX_FOUND
      Candidate file(s): [list or N/A]
      Repro steps: written ([Always|Intermittent|Unknown])

  [✓] Stage 3 — UPDATE
      Intake comment posted to {{TICKET_ID}}
      Sub-task suggestion: [printed for approval | N/A]

  Next steps:
    [ ] Review the intake comment on {{TICKET_ID}}
    [ ] Approve sub-task creation (if suggested)
    [ ] Assign to component owner: [component]
    [ ] Add to sprint: [recommendation]
════════════════════════════════════════════════════════════
```

---

## Variables

- `{{TICKET_ID}}` — Jira ticket ID passed as argument
- `{{TICKET_SYSTEM}}` — from workflow.config.md
- `{{JIRA_PROJECT}}` — from workflow.config.md
- `{{SEVERITY_LABELS}}` — from qa.config.md
- `{{SEVERITY}}` — classification from Stage 1
- `{{PRIORITY}}` — P0/P1/P2/P3 from Stage 1
- `{{COMPONENT}}` — component area from Stage 1
- `{{TICKET_SUMMARY}}` — ticket title + description (first 1500 chars) from Stage 1
- `{{INVESTIGATION_RESULT}}` — fix plan output from Stage 2a
- `{{REPRO_STEPS}}` — reproduction steps from Stage 2b
- `{{TODAY}}` — current date (YYYY-MM-DD)
