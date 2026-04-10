---
description: Produce stakeholder-ready communication artifacts for a feature. 3-stage workflow — executive brief, sign-off request, roadmap update. Argument is a feature name or PRD file path.
---

Run a full stakeholder communication workflow for the feature described in the argument.

You are the **orchestrator**. Do NOT write the brief yourself — spawn dedicated sub-agents
for each stage. Each gets an isolated context window.

---

## Before Starting

Read `product.config.md` and `workflow.config.md`. Extract these variables before spawning any agent:

- `{{FEATURE}}` — argument passed to this command (feature name or PRD file path)
- `{{COMMS_TOOL}}` — `slack`, `teams`, `email`, `confluence`, `notion`, or other
- `{{ROADMAP_TOOL}}` — `productplan`, `aha`, `roadmunk`, `confluence`, `notion`,
  `github-projects`, `jira`, `linear`, or other
- `{{PRD_TOOL}}` — `confluence`, `notion`, `google-docs`, `markdown`, or other
- `{{PRD_APPROVERS}}` — comma-separated list of roles/names who must sign off
- `{{TICKET_SYSTEM}}` — `jira`, `linear`, `github`, `shortcut`, or other
- `{{DOCS_PLATFORM}}` — where engineering docs live

If a PRD file path was passed as the argument, read that file and extract:
- Feature name
- Problem statement
- Primary metric
- Timeline
- Open questions

If `product.config.md` or `workflow.config.md` do not exist, proceed with placeholders
and note them in the output.

---

## Stage 1 — EXECUTIVE BRIEF

Spawn the `stakeholder-advisor` agent.

Agent prompt:
```
You are the stakeholder-advisor agent.

Feature: {{FEATURE}}
PRD content (if available): {{PRD_CONTENT}}
Comms tool: {{COMMS_TOOL}}
PRD approvers: {{PRD_APPROVERS}}

Your task: produce a complete executive brief for this feature. Stakeholders include
executives, sales, customer success, legal, and engineering leads. Write for the
executive audience: outcome-focused, no technical jargon, quantified where possible.

---

OUTPUT 1: THREE-BULLET EXECUTIVE SUMMARY (for 30-second briefing)

Prepare these bullets for a verbal update to leadership — each must fit in one breath:

• Problem:  [One sentence. Quantify the pain if possible: "X% of users abandon at step Y"
            or "Customers report Z as their top unmet need." Never start with "We are..."]

• Solution: [One sentence. Describe what the user can do, not what we built.
            "Users will be able to..." — no technical implementation details.]

• Outcome:  [One measurable sentence. State the primary metric, current value, target,
            and timeline: "[Metric] will improve from [X] to [Y] within [N days/weeks]
            of launch."]

---

OUTPUT 2: ONE-PAGE FEATURE BRIEF

Format this for {{COMMS_TOOL}}. Match the platform's text conventions:
- Slack/Teams: use *bold*, bullet points, short paragraphs, no headers over 3 levels
- Confluence/Notion: use H2/H3 headers, tables, callout boxes
- Email: use plain prose with clear section headings
- Google Docs: use heading styles, one idea per paragraph

---

**What we're building**

[2-3 sentences. User-centric. Describe the experience, not the implementation.
Start from the user's perspective: "Today, [user type] has to [painful current state].
With [feature name], they will be able to [new capability], which means [concrete
benefit in their terms]."]

---

**Why now**

[2-3 sentences. Cover ONE of: market timing, competitive pressure, customer signal
(quote a real customer request if available), strategic alignment, or compliance need.
Be specific: "Three enterprise customers requested this in Q1 and cited it as blocking
renewal." is better than "There is customer demand."]

---

**What it will NOT do** (scope guard)

- [Item 1 — be specific. "Will not replace the existing export feature — that is a
  separate workstream." is better than "Not in scope."]
- [Item 2]
- [Item 3 max — if you have more, the feature is not well-scoped yet]

---

**The one number that defines success**

Metric: [metric name]
Current value: [baseline or "TBD — measuring now"]
Target: [specific value or % change]
Timeline: [N days/weeks after launch]
Why this metric: [one sentence explaining why this is the right number to watch,
and why it cannot be gamed without actually delivering user value]

---

**Timeline**

| Milestone | Target Date | Status |
|-----------|-------------|--------|
| PRD sign-off | [date] | [status] |
| Design complete | [date] | [status] |
| Engineering start | [date] | [status] |
| MVP launch | [date] | [status] |
| Full release | [date] | [status] |

---

**What we need from stakeholders**

Decision needed:
- [Specific decision] — needed from [role] by [date]
  Context: [one sentence on why this decision is blocking]

Resources needed:
- [Resource: eng time / design / legal review / data access / etc.] — [amount/duration]
  Needed by: [date] to hit [milestone]

Approvals needed:
- [What needs sign-off] — from [role/team] — blocking [milestone]

---

OUTPUT 3: RISK REGISTER (3 bullets maximum — flag only real risks, not theoretical ones)

For each risk:
• [Risk name]: [One sentence — what could go wrong and when.]
  Likelihood: High / Medium / Low
  Impact if it occurs: [one sentence]
  Mitigation: [one concrete action already underway or planned, with owner]

If there are no material risks, write: "No material risks identified at this stage.
Review at [milestone] checkpoint."
```
Tools: Read, Glob

Gate: Print the executive brief. Ask: "Brief looks right? Proceed to SIGN-OFF REQUEST? [y/N]"

---

## Stage 2 — SIGN-OFF REQUEST

Spawn the `stakeholder-advisor` agent. Pass Stage 1 output summary (first 2000 chars) as `{{BRIEF_SUMMARY}}`.

Agent prompt:
```
You are the stakeholder-advisor agent.

Feature: {{FEATURE}}
Comms tool: {{COMMS_TOOL}}
PRD tool: {{PRD_TOOL}}
PRD approvers: {{PRD_APPROVERS}}
Brief summary from Stage 1: {{BRIEF_SUMMARY}}

Your task: draft all the communication artifacts needed to collect sign-off and
kick off engineering. Produce three artifacts below.

---

ARTIFACT 1: PRD REVIEW REQUEST

Write a message to {{PRD_APPROVERS}} requesting PRD review and sign-off.
Format for {{COMMS_TOOL}}.

[If Slack/Teams:]
Subject/thread title: PRD Review Needed: {{FEATURE}} — Due [date]

@[approver1] @[approver2] I need your review on the {{FEATURE}} PRD before we
kick off engineering.

*What I need from you:*
• [Approver role 1]: [specific question or decision they own — e.g. "Confirm the
  legal review for data retention is not required for this feature"]
• [Approver role 2]: [specific question or decision they own]

*PRD link:* [{{PRD_TOOL}} — to add before sending]

*Feedback deadline:* [date — 3-5 business days recommended]

*What happens after sign-off:* We start engineering Sprint 1 on [date]. Delay
in sign-off pushes the MVP launch by [N days/weeks].

Please reply with ✅ approved, ❓ questions (I'll schedule 20 mins), or
🚫 blocking concern (explain below).

[If email:]
Subject: [ACTION REQUIRED] PRD Review: {{FEATURE}} — Decision needed by [date]

Hi [name],

I'm requesting your sign-off on the PRD for [{{FEATURE}}] before we begin
engineering. This is a [S/M/L] feature targeting [primary outcome].

Your specific input needed:
[numbered list of decisions or review areas by approver]

PRD location: [{{PRD_TOOL}} link — to add]
Feedback deadline: [date]
Sign-off method: Reply to this email with "approved" or your questions.

If you have concerns that could block this, please flag them by [date-2] so we
have time to address them before the decision deadline.

Thanks,
[PM name — to fill]

---

ARTIFACT 2: ENGINEERING KICKOFF BRIEF

Write a brief for the engineering team. Technical framing is appropriate here.

Format for {{COMMS_TOOL}}:

---
**Engineering Kickoff: {{FEATURE}}**

**What we're building** (technical framing)
[2-3 sentences. You can reference systems, APIs, and data models here.
Describe what the feature does technically, what it touches, and what
new behaviour it introduces.]

**Why this matters — product context for engineers**
[2-3 sentences. Connect the technical work to the user outcome. Engineers
make better decisions when they understand the "why" behind a feature.
Be specific: "This reduces checkout steps from 5 to 2, which our data shows
is the primary driver of mobile conversion drop-off."]

**Technical constraints known upfront**
- [Constraint 1 — e.g. "Must work with the existing OAuth flow — no changes to
  auth infrastructure in scope"]
- [Constraint 2 — e.g. "Response time SLA: < 300ms P95 for the primary action"]
- [Constraint 3 — or: "No known constraints — flag any you discover in tech design"]

**What we're explicitly NOT building (to prevent over-engineering)**
- [Item 1]
- [Item 2]

**Contacts for questions**
- Product: [PM name — to fill] — for scope/requirements questions
- Design: [Designer name — to fill] — for UX/UI questions
- Data: [Data analyst — to fill] — for metrics/instrumentation questions
- [Other team] — [what to contact them about]

**Links**
- PRD: [{{PRD_TOOL}} link — to add]
- Design: [Figma / design tool link — to add]
- Tickets: [{{TICKET_SYSTEM}} epic link — to add]
- Metrics plan: [link to instrumentation doc — to add]

**First milestone: [Sprint 1 goal — user-centric]**
Target date: [date]

---

ARTIFACT 3: INTERNAL ANNOUNCEMENT DRAFT

Write a short announcement for the broader team once engineering kicks off.
Format for {{COMMS_TOOL}}.

[If Slack/Teams — post to product/engineering channel:]
*Kicking off: {{FEATURE}}* 🚀

We're starting work on [{{FEATURE}}] this sprint. Here's the short version:

[2-3 sentences. What we're building, who benefits, and the success metric.
Keep it human — this is not a press release. Write as a colleague updating
the team, not a PM updating stakeholders.]

PRD / details: [link — to add]
Questions? Tag me here or grab 15 mins: [calendar link — to add]

[If email — company or team all-hands update:]
Subject: Engineering starting on [{{FEATURE}}]

Hi team,

Quick update: we're starting engineering on [{{FEATURE}}] this [sprint/week].

[2-3 sentence description of what we're building and why.]

Target launch: [milestone date]
Success metric: [primary metric and target]

More details in the PRD: [link — to add]

[PM name]
```
Tools: Read

Gate: Ask: "Communication drafts look good? Proceed to ROADMAP UPDATE? [y/N]"

---

## Stage 3 — ROADMAP UPDATE

Spawn the `product-manager` agent. Pass Stage 1 brief summary (first 1500 chars) as `{{BRIEF_SUMMARY}}`.

Agent prompt:
```
You are the product-manager agent.

Feature: {{FEATURE}}
Roadmap tool: {{ROADMAP_TOOL}}
Ticket system: {{TICKET_SYSTEM}}
Brief summary: {{BRIEF_SUMMARY}}

Your task: write roadmap update instructions tailored to {{ROADMAP_TOOL}}.
The roadmap item should reflect the current state of the feature: approved,
entering engineering, with a known primary metric and timeline.

Produce the roadmap item entry AND the instructions for adding it to the tool.

---

ROADMAP ITEM CONTENT (tool-agnostic):

Title: {{FEATURE}}
Status: In Discovery → Ready for Development [update to whichever is correct]
Time horizon: Now (this quarter) / Next (next 1-2 quarters) / Later (6+ months)
  [choose based on timeline from Stage 1 brief]
Primary success metric: [from Stage 1 brief]
Target: [metric value and timeline]
Owner: [PM — to fill]
Engineering owner: [to fill]
Dependencies: [list from Stage 1 brief, or "None identified"]
Link to PRD: [{{PRD_TOOL}} — to fill]
Link to tickets: [{{TICKET_SYSTEM}} — to fill]
Confidence: High / Medium / Low [based on whether PRD is signed off]

---

TOOL-SPECIFIC INSTRUCTIONS:

[If ProductPlan:]
1. Open your roadmap board
2. Create a new feature bar in the [Now/Next/Later] swimlane
3. Set fields:
   - Name: [title]
   - Description: [2-sentence user-centric description from brief]
   - Status: [Planned / In Progress]
   - Owner: [to fill]
   - Start: [sprint start date]
   - End: [MVP launch date]
   - Metric: [primary metric name]
   - Tags: [product area / team tag]
4. Add the PRD link to the "Notes" field
5. Link dependent items using the dependency feature

[If Aha!:]
1. Navigate to Features → [your product line]
2. Create a Feature record:
   - Name: [title]
   - Initiative: [parent initiative — to fill]
   - Description: [user-centric description]
   - Goal: [primary metric target]
   - Release: [target release version or date]
   - Score: [set RICE or custom scoring — to fill]
3. Set workflow status: "Ready for Development"
4. Add the PRD URL in the Reference URLs field
5. Create a Release note summary for the changelog

[If Confluence or Notion roadmap page:]
Add this row to your roadmap table:

| Feature | Quarter | Status | Owner | Primary Metric | Target | PRD | Notes |
|---------|---------|--------|-------|----------------|--------|-----|-------|
| {{FEATURE}} | [Q] | Ready for Dev | [PM] | [metric name] | [target] | [link] | [dependencies] |

Also add a detail block below the table:

**{{FEATURE}}**
- What: [2 sentences]
- Why now: [1 sentence]
- Success: [metric name] from [current] to [target] by [date]
- Dependencies: [list]

[If GitHub Projects:]
Create an Epic issue in the [product roadmap] project:

Title: [EPIC] {{FEATURE}}
Labels: epic, roadmap, [team label], [quarter label]
Body:
## Objective
[2 sentences — outcome-focused, no jargon]

## Success Metric
[metric name]: [current] → [target] by [date]

## Scope
In: [3-4 bullet items]
Out: [2-3 explicit exclusions from brief]

## Timeline
- [ ] PRD signed off: [date]
- [ ] Sprint 1 start: [date]
- [ ] MVP launch: [date]

## Links
- PRD: [link]
- Design: [link]

[If Jira (epic for roadmap tracking):]
Create an Epic:
  Summary: [ROADMAP] {{FEATURE}}
  Description:
    Objective: [outcome-focused description]
    Success metric: [metric]: [current] → [target]
    Time horizon: [Now/Next/Later]
  Custom fields:
    - Objective: [metric and target]
    - Time horizon: [Now/Next/Later]
    - Product area: [to fill]
  Fix version: [target release — to fill]
  Priority: [High/Medium based on P0 story count]

[If Linear:]
Create a Project:
  Name: {{FEATURE}}
  Status: Planned
  Description: [2-sentence user-centric description]
  Target date: [MVP launch date]
  Lead: [PM — to fill]
  Health: On Track
  Add to Roadmap view: Yes
```
Tools: Read

---

## Summary Report

After all three stages complete, print:

```
════════════════════════════════════════════════════════
  Feature Brief — {{FEATURE}}
════════════════════════════════════════════════════════
  [✓] Stage 1 — EXECUTIVE BRIEF    3-bullet summary + 1-pager + risk register
  [✓] Stage 2 — SIGN-OFF REQUEST   PRD review request + eng kickoff + announcement
  [✓] Stage 3 — ROADMAP UPDATE     {{ROADMAP_TOOL}} entry + instructions
════════════════════════════════════════════════════════

Artifacts produced:
  1. Executive brief (formatted for {{COMMS_TOOL}})
  2. PRD review request → {{PRD_APPROVERS}}
  3. Engineering kickoff brief
  4. Internal announcement draft
  5. Roadmap update for {{ROADMAP_TOOL}}

Primary metric: [name] — current: [value] — target: [value] by [date]
Risks flagged: [count] ([names])

Next actions:
  [ ] Add PRD link to the review request before sending
  [ ] Send PRD review request to: {{PRD_APPROVERS}}
  [ ] Schedule engineering kickoff for Sprint 1 start
  [ ] Post roadmap update to {{ROADMAP_TOOL}}
  [ ] Post team announcement in {{COMMS_TOOL}} when engineering starts
════════════════════════════════════════════════════════
```

---

## Variables

- `{{FEATURE}}` = argument passed to this command (feature name or PRD file path)
- `{{PRD_CONTENT}}` = contents of PRD file if a file path was passed as the argument
- `{{BRIEF_SUMMARY}}` = Stage 1 agent output (first 2000 chars for Stage 2 / first 1500 chars for Stage 3)
- `{{COMMS_TOOL}}`, `{{ROADMAP_TOOL}}`, `{{PRD_TOOL}}`, `{{PRD_APPROVERS}}`,
  `{{TICKET_SYSTEM}}`, `{{DOCS_PLATFORM}}` = from product.config.md / workflow.config.md
