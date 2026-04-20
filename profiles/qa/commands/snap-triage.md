---
description: Daily Freshservice incident triage workflow. Fetches open incidents, classifies severity, investigates the codebase for a fix plan, posts triage comments, and creates Jira bug tickets for escalated items. Run each morning before sprint stand-up.
argument: optional — pass a specific Freshservice ticket ID (e.g. "12345") to triage a single ticket instead of the full queue
---

Run the full daily Freshservice incident triage workflow.

You are the **orchestrator**. Do NOT investigate incidents, write comments, or call any API
yourself — spawn a dedicated sub-agent for each stage using the `Agent` tool.

---

## Before starting

Read `freshservice.config.md`, `qa.config.md`, and `workflow.config.md`. Extract:

- `{{FRESHSERVICE_DOMAIN}}` — from freshservice.config.md `freshservice_domain`
- `{{API_KEY_ENV}}` — from freshservice.config.md `freshservice_api_key_env`
- `{{FILTER_STATUS}}` — from freshservice.config.md `freshservice_filter_status`
- `{{ESCALATE_SEVERITY}}` — from freshservice.config.md `escalate_severity`
- `{{COMMENT_SEVERITY}}` — from freshservice.config.md `comment_only_severity`
- `{{JIRA_PROJECT}}` — from freshservice.config.md `jira_project_key`
- `{{TICKET_SYSTEM}}` — from workflow.config.md (should be Jira)
- `{{SEVERITY_LABELS}}` — from qa.config.md

If `freshservice.config.md` is missing, print:
```
ERROR: freshservice.config.md not found.
Run: cp freshservice.config.md.example freshservice.config.md and fill in your details.
```
Then stop.

If a specific ticket ID was passed as argument, set `{{SINGLE_TICKET_ID}}` and skip Stage 1 (go directly to Stage 2 with that one ticket).

---

## Stage 1 — FETCH

Spawn `freshservice-analyst`.

Agent prompt:
```
You are the freshservice-analyst running a pre-flight check and fetching open incidents.

Domain: {{FRESHSERVICE_DOMAIN}}
API key env var: {{API_KEY_ENV}}
Status filter: {{FILTER_STATUS}}

Read freshservice.config.md.
Read profiles/qa/skills/freshservice-triage/SKILL.md.

1. Run the pre-flight check from the skill. If it fails, stop and report the error clearly.
2. Fetch open incidents using the fetch pattern from the skill.
3. For each incident, output ONLY: ticket ID, subject, status, created_at, requester name.
   Do not include body text, attachments, or PII beyond the requester name.

Output a numbered list:
#<id> | <subject> | status: <status> | created: <date> | requester: <name>

Tools: Bash, Read
```

Print the list. If 0 incidents: print "No open incidents matching the filter. Triage complete." and stop.

---

## Stage 2 — ANALYZE

Spawn `freshservice-analyst`.

Agent prompt:
```
You are the freshservice-analyst classifying incidents for triage.

Incident list from Stage 1:
{{STAGE_1_OUTPUT}}

Domain: {{FRESHSERVICE_DOMAIN}}
API key env var: {{API_KEY_ENV}}
Escalate if severity: {{ESCALATE_SEVERITY}}
Comment only if severity: {{COMMENT_SEVERITY}}

Read freshservice.config.md.
Read profiles/qa/agents/freshservice-analyst.md for the severity and decision framework.
Read profiles/qa/skills/freshservice-triage/SKILL.md for escalation criteria.

For each incident:
1. Fetch the full ticket body: GET /api/v2/tickets/<id>
2. Classify severity (Critical / High / Medium / Low) using the framework in your agent file
3. Decide: ESCALATE / COMMENT / SKIP — using the escalation criteria from the skill
4. Write a 1-sentence justification for the decision

Output a table:
| FS ID | Subject (truncated to 60 chars) | Severity | Decision | Reason |
|-------|----------------------------------|----------|----------|--------|

Tools: Bash, Read
```

Print the analysis table.

**Gate:** Ask "Proceed with codebase investigation and posting triage actions? [y/N]"
If the user answers N: stop and print the table for manual review.

---

## Stage 3 — INVESTIGATE (ESCALATE tickets only)

For each ticket with Decision = ESCALATE, spawn `bug-triager` **in parallel** (one agent per ticket, up to 3 at a time).

Agent prompt per ticket:
```
You are the bug-triager investigating a Freshservice incident to identify a fix in the codebase.

Incident #{{FS_ID}}: {{SUBJECT}}
Description:
{{TICKET_BODY_FIRST_1500_CHARS}}

Read profiles/qa/agents/bug-triager.md.
Read profiles/qa/skills/freshservice-triage/SKILL.md (Codebase Investigation Checklist).

Investigate the codebase:
1. Extract the error message, feature name, or component from the description above
2. Grep for the exact error string or relevant function/component name
3. Glob for files in the suspected component directory
4. Read candidate files — find the code path that could produce this behaviour
5. Form a hypothesis: "This is likely caused by X in path/to/file:N because Y"
6. Rate confidence: High / Medium / Low

If you find a fix path, output:
FIX_FOUND
Hypothesis: [description]
Confidence: High | Medium | Low
Candidate files:
  - path/to/file.ts:42 — [why suspicious]
Suggested fix: [1–3 sentence description of what to change]

If no code path found after exhausting reasonable searches, output:
NO_FIX_FOUND

Tools: Grep, Glob, Read
```

Collect all investigation results. Label each with its FS ticket ID.

---

## Stage 4 — COMMENT

Spawn `freshservice-analyst`.

Agent prompt:
```
You are the freshservice-analyst posting triage notes on Freshservice tickets.

Domain: {{FRESHSERVICE_DOMAIN}}
API key env var: {{API_KEY_ENV}}
Today's date: {{TODAY}}

Analysis results from Stage 2:
{{STAGE_2_OUTPUT}}

Investigation results from Stage 3:
{{STAGE_3_OUTPUT}}

Read freshservice.config.md.
Read profiles/qa/skills/freshservice-triage/SKILL.md for the comment template and posting pattern.

For every ticket with Decision = ESCALATE or COMMENT (skip SKIP tickets):
1. Build the triage comment using the template from the skill:
   - Fill in Decision, Severity, date
   - For ESCALATE tickets: include the fix plan from Stage 3 (or "Root cause not identified" if NO_FIX_FOUND)
   - For COMMENT tickets: Analysis section only, no fix plan section
   - Jira key: N/A at this stage (will be updated after Stage 5 if needed)
2. Post the comment via POST /api/v2/tickets/<id>/notes
3. Report success or failure per ticket

Output: list of posted comments with success/failure status.

Tools: Bash, Read
```

---

## Stage 5 — CREATE JIRA

Spawn `jira-advisor` for ESCALATE tickets that have no existing Jira bug linked.

Agent prompt:
```
You are the jira-advisor creating Bug tickets from escalated Freshservice incidents.

Jira project: {{JIRA_PROJECT}}
Ticket system: {{TICKET_SYSTEM}}

Incidents to escalate (from Stage 2 analysis):
{{ESCALATE_LIST}}

Codebase investigation results (from Stage 3):
{{STAGE_3_OUTPUT}}

Read profiles/product/skills/jira-integration/SKILL.md — use its pre-flight check and Bug creation pattern.
Read workflow.config.md for Jira configuration.

For each ESCALATE incident:
1. Run the jira-integration pre-flight check
2. Create a Jira Bug ticket with:
   Title: [Bug] [Component if known]: <Freshservice ticket subject>
   Type: Bug
   Priority: based on severity (Critical→Highest, High→High, Medium→Medium, Low→Low)
   Body sections:
     ## Summary
     [2–3 sentence summary from Freshservice ticket description]

     ## Steps to Reproduce
     [From Freshservice ticket, formatted as numbered steps]

     ## Expected Result / Actual Result
     [From Freshservice ticket]

     ## Freshservice Reference
     Freshservice ticket: #<FS_ID>

     ## Suggested Fix
     [Fix plan from Stage 3 if FIX_FOUND, or "Root cause under investigation" if NO_FIX_FOUND]

     ## Regression Test Required
     Yes — a regression test must be written before this ticket can be closed.

   Labels: bug, freshservice-escalation
3. After creating, post a follow-up note on the Freshservice ticket updating the Jira key:
   "Jira bug created: {{JIRA_PROJECT}}-<key>"
   (Use the Freshservice API pattern from profiles/qa/skills/freshservice-triage/SKILL.md)

Output: list of FS ticket IDs → Jira keys created.

Tools: Bash, Read
```

---

## Stage 6 — REPORT

Print the daily triage summary:

```
════════════════════════════════════════════════════════════
  Daily Freshservice Triage — {{TODAY}}
════════════════════════════════════════════════════════════
  Total incidents reviewed:  N

  ESCALATED to Jira:         M
    ├── With fix plan:        X
    └── No fix found:         Y

  COMMENT only:              K
  SKIPPED (noise/dup):       J

  Jira tickets created:
    PROJ-NNN ← FS #12345 — [subject]
    PROJ-NNN ← FS #12346 — [subject]

  Next steps:
    [ ] Assign Jira tickets to component owners
    [ ] Review COMMENT-only incidents in next sprint grooming
════════════════════════════════════════════════════════════
```

---

## Variables

- `{{FRESHSERVICE_DOMAIN}}` — from freshservice.config.md
- `{{API_KEY_ENV}}` — env var name for Freshservice API key
- `{{FILTER_STATUS}}` — incident status filter
- `{{ESCALATE_SEVERITY}}` — severity levels that trigger Jira creation
- `{{COMMENT_SEVERITY}}` — severity levels that get comment only
- `{{JIRA_PROJECT}}` — target Jira project key
- `{{TICKET_SYSTEM}}` — from workflow.config.md
- `{{TODAY}}` — current date (YYYY-MM-DD)
- `{{STAGE_1_OUTPUT}}` — incident list from Stage 1
- `{{STAGE_2_OUTPUT}}` — analysis table from Stage 2
- `{{STAGE_3_OUTPUT}}` — investigation results from Stage 3
- `{{ESCALATE_LIST}}` — filtered list of ESCALATE tickets
- `{{TICKET_BODY_FIRST_1500_CHARS}}` — Freshservice ticket description, truncated
