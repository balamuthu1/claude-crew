Run a full PRD development workflow for the feature described in the argument.

You are the **orchestrator**. Do NOT write the PRD yourself — spawn dedicated sub-agents
for each stage. Each gets an isolated context window.

**For stages 3 and 4 (stories + metrics): call `Agent` twice in a single message to run them in parallel.**

---

## Before starting

Read `product.config.md` and `workflow.config.md`. Extract:
- `{{PRD_TOOL}}` — where PRDs are written (confluence, notion, google-docs, markdown, etc.)
- `{{TICKET_SYSTEM}}` — for story creation
- `{{STORY_FORMAT}}` — user-story or job-story
- `{{AC_FORMAT}}` — gherkin or checklist
- `{{ESTIMATION_SCALE}}` — fibonacci, t-shirt, none
- `{{ANALYTICS_PLATFORM}}` — amplitude, mixpanel, ga4, etc.
- `{{ROADMAP_TOOL}}` — where the roadmap lives

---

## Stage Definitions

### Stage 1 — DISCOVERY
Spawn the `product-manager` agent.

Agent prompt:
```
You are the product-manager agent.

Feature request: {{FEATURE}}

Read product.config.md and workflow.config.md.

Facilitate a product discovery session. Produce:

1. **Problem statement**
   - Who has this problem? (specific user type, not "all users")
   - What are they trying to accomplish? (job to be done)
   - How do they currently solve it? (workaround or alternative)
   - What is the cost of the current solution? (time, money, frustration, risk)

2. **Opportunity sizing**
   - Estimated number of affected users (order of magnitude)
   - Frequency: how often do they hit this problem?
   - Business impact: revenue, retention, growth, compliance, cost reduction

3. **Solution space** (2-3 options)
   For each option:
   - Brief description (1-2 sentences)
   - Key trade-offs (faster but weaker / more powerful but complex)
   - Implementation effort estimate (S/M/L/XL)
   - Risk factors

4. **Recommended direction**
   - Which option and why
   - What we're explicitly NOT doing and why (scope guard)

5. **Open questions** (blockers that need answers before writing the full PRD)
   - [Question] | Owner: [role] | Needed by: [date]

Output a discovery document the prd-author can use immediately.
```
Tools: Read, Glob

Gate: Print discovery summary. Ask "Does this capture the right problem? Proceed to WRITE PRD? [y/N]"

---

### Stage 2 — WRITE PRD
Spawn the `prd-author` agent.

Agent prompt:
```
You are the prd-author agent.

Feature: {{FEATURE}}

Discovery from Stage 1:
{{DISCOVERY_OUTPUT}}

Read product.config.md:
  - PRD tool: {{PRD_TOOL}}
  - Story format: {{STORY_FORMAT}}
  - AC format: {{AC_FORMAT}}
  - Sign-off required from: {{PRD_APPROVERS}}

Write a complete PRD formatted for {{PRD_TOOL}}. Use this structure:

---
# PRD: {{FEATURE}}

**Status:** Draft  
**Author:** [to fill]  
**Created:** {{TODAY}}  
**Last updated:** {{TODAY}}

---

## 1. Problem Statement
[One paragraph, user-centric. No solution language.]

## 2. Goals
- [Measurable outcome 1 — e.g. Reduce checkout drop-off by 15%]
- [Measurable outcome 2]

## 3. Non-Goals
- [Explicitly out of scope item 1] — reason
- [Explicitly out of scope item 2]

## 4. User Personas
For each user type affected:
**[Persona name]**: [1-sentence description of who they are and their goal]

## 5. User Stories / Jobs
[Use {{STORY_FORMAT}} format for each story]

## 6. Functional Requirements
### Core flows
[Step-by-step description of each user flow — numbered steps]

### Error states and edge cases
| Scenario | Expected behaviour | User message |
|----------|-------------------|--------------|
| [scenario] | [behaviour] | [message shown] |

### Constraints and business rules
- [Rule 1 — e.g. Users can only have one active subscription]

## 7. Acceptance Criteria
[Use {{AC_FORMAT}} format]

For each requirement:
[Given context / When action / Then result]

## 8. Success Metrics
| Metric | Current baseline | Target | Measurement method |
|--------|-----------------|--------|-------------------|
| [metric] | [value] | [value] | [how tracked in {{ANALYTICS_PLATFORM}}] |

## 9. Out of Scope
- [Item] — (reason / future consideration)

## 10. Dependencies
| Dependency | Type | Owner | Status |
|-----------|------|-------|--------|
| [dependency] | [API / Design / Data] | [team] | [status] |

## 11. Open Questions
| Question | Owner | Due date | Status |
|----------|-------|----------|--------|
| [question] | [role] | [date] | Open |

## 12. Sign-off
| Role | Name | Date | Status |
|------|------|------|--------|
| [required approver] | | | Pending |
---

Rules:
- Every requirement must be testable. If it can't be tested, rewrite it.
- No vague words: "fast", "easy", "simple" — replace with specific criteria.
- Every error state needs a user-facing message and a recovery path.
- Success metrics must reference {{ANALYTICS_PLATFORM}} for tracking.
```
Tools: Read, Write

Gate: Show PRD structure summary. Ask "Proceed to STORIES + METRICS in parallel? [y/N]"

---

### Stage 3 — USER STORIES  ← spawn in PARALLEL with Stage 4
Spawn the `user-story-writer` agent.

Agent prompt:
```
You are the user-story-writer agent.

Feature: {{FEATURE}}

PRD from Stage 2:
{{PRD_OUTPUT}}

Read product.config.md:
  - Story format: {{STORY_FORMAT}}
  - Estimation scale: {{ESTIMATION_SCALE}}
  - Ticket system: {{TICKET_SYSTEM}}

Break the PRD into sprint-ready stories. For EACH story:

**Story [N]: [One-line summary]**

Format: {{STORY_FORMAT}}
[Write the full story statement]

**Context:** [1-2 sentences on why this story exists]

**Acceptance Criteria:**
[Write using {{AC_FORMAT}}]

**Edge cases:**
- [Scenario]: [expected behaviour]

**Out of scope:** [what this story explicitly does NOT include]

**Dependencies:** [other stories or external dependencies — list story numbers]

**Estimate:** [{{ESTIMATION_SCALE}} points/size]
**Priority:** [P0 / P1 / P2]

---

After all stories, produce:

**Implementation sequence** — the order stories should be built, with rationale:
1. Story [N] first because [reason — e.g. "unblocks stories 3, 4, 5"]
2. Story [M] second because...

**MVP boundary** — clearly mark which stories are MVP vs post-MVP

**Ticket creation instructions for {{TICKET_SYSTEM}}:**
For each story:
"Create [issue type] in [project]: [summary] | Priority: [P0/P1/P2] | Points: [N]"
```
Tools: Read

---

### Stage 4 — METRICS & EVENTS  ← spawn in PARALLEL with Stage 3
Spawn the `metrics-analyst` agent.

Agent prompt:
```
You are the metrics-analyst agent.

Feature: {{FEATURE}}

PRD from Stage 2:
{{PRD_OUTPUT}}

Read product.config.md:
  - Analytics platform: {{ANALYTICS_PLATFORM}}

1. **Primary metric** (the ONE number that determines success/failure):
   - Name:
   - Definition: [precise business definition]
   - Calculation: [exact formula]
   - Current baseline: [or "TBD — measure before launch"]
   - Target: [absolute value or % change]
   - Measurement window: [e.g. "30 days post-launch"]

2. **Secondary metrics** (leading indicators):
   [2-4 metrics that predict the primary metric will improve]

3. **Guardrail metrics** (must NOT regress):
   [2-3 metrics that, if they drop, indicate a problem with the feature]

4. **Analytics event schema** — for each user action to track:

   Event: event_name_snake_case
   Trigger: [when this fires — user action description]
   Properties:
     - user_id: string (anonymised)
     - session_id: string
     - [context property]: [type] — [description]
   PII fields: [list any PII — must be anonymised before sending]
   Platform: {{ANALYTICS_PLATFORM}}

5. **Instrumentation checklist** — what the engineering team must implement:
   - [ ] [Event name]: [implementation notes — where in the code to fire it]

6. **Baseline measurement plan**:
   "Before launching, measure [baseline metric] for [N days] to establish pre-launch baseline."

Format event schemas as a table that can be pasted into {{DOCS_PLATFORM}}.
```
Tools: Read

After both Stage 3 and Stage 4 complete, print their combined outputs.
Gate: Ask "Proceed to STAKEHOLDER SUMMARY? [y/N]"

---

### Stage 5 — STAKEHOLDER SUMMARY
Spawn the `stakeholder-advisor` agent.

Agent prompt:
```
You are the stakeholder-advisor agent.

Feature: {{FEATURE}}

Full PRD and stories from previous stages:
{{PRD_OUTPUT}}
{{STORIES_OUTPUT}}

Read product.config.md:
  - Stakeholders / approvers: {{PRD_APPROVERS}}
  - Comms tool: {{COMMS_TOOL}}
  - Roadmap tool: {{ROADMAP_TOOL}}

Produce:

1. **Executive summary** (3 bullets max — for a 30-second briefing):
   - Problem: [one sentence]
   - Solution: [one sentence]
   - Expected outcome: [one measurable sentence]

2. **One-page brief** formatted for {{COMMS_TOOL}} announcement:
   - What we're building and why (user-centric)
   - What it will NOT do (scope guard)
   - Success metric (the one number)
   - Timeline: [MVP stories] / [post-MVP]
   - What we need from stakeholders (decisions, approvals, resources)

3. **PRD sign-off request** message for {{COMMS_TOOL}}:
   Draft a message to {{PRD_APPROVERS}} requesting review and sign-off.
   Include: link to PRD in {{PRD_TOOL}}, deadline for feedback, what decisions are needed.

4. **Roadmap update** for {{ROADMAP_TOOL}}:
   Roadmap item:
   - Title: [feature name]
   - Status: In Discovery → Ready for Development
   - Time horizon: Now / Next / Later
   - Success metric: [primary metric]
   - Owner: [PM name — to fill]
```
Tools: Read

---

## PRD Workflow Summary Report

After all stages complete, print:

```
════════════════════════════════════════════════════════
  PRD Workflow — {{FEATURE}}
════════════════════════════════════════════════════════
  [✓] Stage 1 — DISCOVERY       Problem defined, [N] options evaluated
  [✓] Stage 2 — PRD             Written for {{PRD_TOOL}}
  [✓] Stage 3 — STORIES         [N stories: P0:N P1:N P2:N] for {{TICKET_SYSTEM}}
  [✓] Stage 4 — METRICS         [N events defined] for {{ANALYTICS_PLATFORM}}
  [✓] Stage 5 — STAKEHOLDERS    Executive summary + sign-off request ready
════════════════════════════════════════════════════════

Pending actions:
  [ ] Share PRD in {{PRD_TOOL}} for sign-off from: {{PRD_APPROVERS}}
  [ ] Create stories in {{TICKET_SYSTEM}} (see Stage 3 output)
  [ ] Instrument events in {{ANALYTICS_PLATFORM}} (see Stage 4 output)
  [ ] Measure baseline before launch
  [ ] Update roadmap in {{ROADMAP_TOOL}}
```

---

## Variables

- `{{FEATURE}}` = argument passed to this command
- `{{DISCOVERY_OUTPUT}}` = Stage 1 output (first 3000 chars)
- `{{PRD_OUTPUT}}` = Stage 2 output (first 3000 chars)
- `{{STORIES_OUTPUT}}` = Stage 3 output summary
- `{{PRD_TOOL}}`, `{{TICKET_SYSTEM}}`, `{{STORY_FORMAT}}`, `{{AC_FORMAT}}`,
  `{{ESTIMATION_SCALE}}`, `{{ANALYTICS_PLATFORM}}`, `{{ROADMAP_TOOL}}`,
  `{{PRD_APPROVERS}}`, `{{COMMS_TOOL}}` = from product.config.md / workflow.config.md
- `{{TODAY}}` = current date
