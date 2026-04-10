---
description: Break a feature or epic into sprint-ready user stories. 3-stage workflow — decompose, refine, finalize tickets. Argument is a feature description or epic ID.
---

Run a full user story breakdown workflow for the feature or epic described in the argument.

You are the **orchestrator**. Do NOT write stories yourself — spawn dedicated sub-agents
for each stage. Each gets an isolated context window.

---

## Before Starting

Read `product.config.md` and `workflow.config.md`. Extract these variables before spawning any agent:

- `{{FEATURE}}` — argument passed to this command (feature description or epic ID)
- `{{STORY_FORMAT}}` — `user-story` ("As a... I want... So that...") or `job-story` ("When... I want... So I can...")
- `{{AC_FORMAT}}` — `gherkin` (Given/When/Then) or `checklist` (- [ ] observable criterion)
- `{{ESTIMATION_SCALE}}` — `fibonacci` (1,2,3,5,8,13), `t-shirt` (XS/S/M/L/XL), or `none`
- `{{TICKET_SYSTEM}}` — `jira`, `linear`, `github`, `shortcut`, or other
- `{{SPRINT_LENGTH}}` — e.g. `1 week`, `2 weeks`
- `{{PRD_APPROVERS}}` — from workflow.config.md (for grooming invite)
- `{{DOCS_PLATFORM}}` — from workflow.config.md (for sprint plan doc)

If `product.config.md` or `workflow.config.md` do not exist, use these defaults:
- `{{STORY_FORMAT}}` = `user-story`
- `{{AC_FORMAT}}` = `gherkin`
- `{{ESTIMATION_SCALE}}` = `fibonacci`
- `{{TICKET_SYSTEM}}` = `jira`
- `{{SPRINT_LENGTH}}` = `2 weeks`

---

## Stage 1 — EPIC DECOMPOSITION

Spawn the `user-story-writer` agent.

Agent prompt:
```
You are the user-story-writer agent.

Feature / Epic: {{FEATURE}}

Read product.config.md and workflow.config.md to confirm:
  - Story format: {{STORY_FORMAT}}
  - AC format: {{AC_FORMAT}}
  - Estimation scale: {{ESTIMATION_SCALE}}
  - Sprint length: {{SPRINT_LENGTH}}
  - Ticket system: {{TICKET_SYSTEM}}

Your task: decompose the feature or epic into a complete, ordered set of user stories
ready for sprint planning. Every story must be independently deliverable — a vertical
slice that delivers value on its own.

For EACH story, produce the full block below:

---

**Story [N]: [One-line summary — imperative, user-centric, no tech jargon]**

**Format:** {{STORY_FORMAT}}

[If user-story:]
As a [specific user type — not "user"],
I want [specific capability or action],
So that [concrete benefit or outcome for them].

[If job-story:]
When [situation / trigger that causes this need],
I want [specific capability or action],
So I can [goal or desired outcome].

**Context:** [1-2 sentences. Why does this story exist? What job is the user trying
to do? Link it to the epic goal.]

**Acceptance Criteria:** (format: {{AC_FORMAT}})

[If gherkin:]
Scenario: [scenario name — describe the flow, not the feature]
  Given [precondition / initial state — describe state, not action]
  When  [user action — specific and observable]
  Then  [expected outcome — what the user sees, gets, or can do]
  And   [additional outcome, if necessary]

Scenario: [validation / error scenario name]
  Given [user is on the relevant screen/state]
  When  [user takes the action that triggers validation]
  Then  [validation message or error shown — quote the exact message if fixed]

[Add scenarios for: happy path, validation, error states, edge cases, empty states,
accessibility. Minimum 3 scenarios per story, maximum 8.]

[If checklist:]
- [ ] [Observable criterion — starts with a verb: Shows, Displays, Allows, Prevents,
      Redirects, Returns. Uses concrete values, not vague words.]
[Minimum 3 criteria, maximum 8.]

**Edge cases:**
- [Scenario description]: [Expected behaviour — what should happen]
- [Scenario description]: [Expected behaviour]

**Out of scope:** [Explicit list of what this story does NOT cover. This prevents
scope creep in sprint. Write at least 2 items.]

**Dependencies:**
- Story [N] — [what this story needs from that story]
- [External system or team] — [what is needed]
- (or: None)

**Estimate:** [{{ESTIMATION_SCALE}} — value with brief justification, e.g. "5 — two
UI states + one API call + validation logic"]

**Priority:**
- P0 — must have MVP (product does not work without this)
- P1 — should have (high value, not day-one blocker)
- P2 — nice to have (polish, edge cases, power users)

---

Repeat the block above for every story in the epic. Number them Story 1, Story 2, etc.

After all story blocks, produce:

---

**Implementation Sequence** — recommended build order with rationale:

1. Story [N] — [Reason: e.g. "foundational data model, unblocks all other stories"]
2. Story [N] — [Reason: e.g. "core happy path, enables first user testing"]
3. Story [N] — [Reason: e.g. "depends on Story 1, can be built in parallel with Story 3"]
[Continue for all stories]

**MVP Boundary:**

MVP (Stories that together deliver a working, testable feature end-to-end):
- Story [N]: [one-line reason it's MVP]
- Story [N]: [one-line reason it's MVP]

Post-MVP (Valuable but not blocking launch):
- Story [N]: [one-line reason it can be deferred]
- Story [N]: [one-line reason it can be deferred]

**Ticket Creation Instructions for {{TICKET_SYSTEM}}:**

[For Jira:]
For each story, create a Story issue:
  Summary: [story one-line summary]
  Issue type: Story
  Priority: [Blocker for P0 / High for P1 / Medium for P2]
  Story points: [estimate]
  Labels: sprint-ready (if all AC written and no open questions) OR needs-refinement
  Epic link: [epic name/key — to fill in]

[For Linear:]
For each story, create an Issue:
  Title: [story summary]
  Priority: [Urgent/High/Medium/Low]
  Estimate: [estimate]
  Labels: sprint-ready OR needs-refinement
  Cycle: [to assign]

[For GitHub Issues:]
For each story, create an Issue:
  Title: [story summary]
  Labels: user-story, p0/p1/p2, sprint-ready OR needs-refinement
  Milestone: [to assign]
  Project estimate: [estimate]

[For Shortcut:]
For each story, create a Story:
  Name: [story summary]
  Type: feature
  Priority: p0/p1/p2
  Estimate: [estimate]
  Labels: sprint-ready OR needs-refinement
```
Tools: Read, Glob

Gate: Count total stories (MVP vs post-MVP split). Print:
```
Stage 1 complete: [N] total stories decomposed
  MVP:      [N stories] (P0: N, P1: N)
  Post-MVP: [N stories] (P1: N, P2: N)
```
Ask: "Stories look good? Proceed to REFINEMENT? [y/N]"

---

## Stage 2 — STORY REFINEMENT

Spawn the `product-manager` agent. Pass the full Stage 1 output (first 3000 chars) as `{{DECOMPOSITION_OUTPUT}}`.

Agent prompt:
```
You are the product-manager agent.

Feature: {{FEATURE}}
Sprint length: {{SPRINT_LENGTH}}
Estimation scale: {{ESTIMATION_SCALE}}
AC format: {{AC_FORMAT}}

Stories from Stage 1:
{{DECOMPOSITION_OUTPUT}}

Your task: perform a rigorous quality review of every story. Act as a senior PM
doing backlog refinement. Apply the Definition of Ready to each story and flag
every issue with a concrete fix.

For each story, run through this checklist:

[ ] INDEPENDENTLY DELIVERABLE — Can this story be built, tested, and released
    without simultaneously releasing another story?
    → If no: either split the dependency into a shared foundation story, or merge
      the two stories into one.

[ ] SPRINT-SIZED — Can one developer complete this in {{SPRINT_LENGTH}} alone?
    → If no: split using one of these patterns:
      - By workflow step (enter email / verify email / confirm registration)
      - By data variation (search by name / search by date)
      - By error handling (happy path / validation / server errors as separate stories)
      - By platform (web / mobile)

[ ] TESTABLE ACCEPTANCE CRITERIA — Could a QA engineer write an automated test
    from each criterion/scenario without asking the PM any questions?
    → If no: rewrite the criterion with concrete values, observable outcomes,
      and no vague language ("works", "fast", "properly", "correctly", "easy").

[ ] SCOPE GUARD IN PLACE — Does the "Out of scope" section prevent the three
    most likely ways a developer might over-build this story?
    → If no: add the missing scope guards.

[ ] ESTIMATE IS JUSTIFIED — Is the estimate based on complexity, not defaulted
    to a round number?
    → If everything is "M" or "5": flag for re-estimation with justification.

[ ] PRIORITY IS COHERENT — Do the P0 stories together form a working feature
    end-to-end? Can a user accomplish the core job with only P0 stories?
    → If no: promote the minimum additional stories needed to P0, or split a
      story to isolate the P0 part.

[ ] NO TECHNICAL TASK DISGUISED AS A USER STORY — Stories must describe user
    value, not engineering work.
    → "Migrate database schema to v2" is a tech task, not a user story.
    → Convert tech tasks to: "Tech Task: [description] | Needed to unblock Story N"

After reviewing all stories, output:

**Refinement Report:**

Stories with no issues: [count]

Stories changed:
- Story [N] — [change type: split / merged / criteria rewritten / priority changed /
  converted to tech task] — [one sentence explaining why]

Stories split into sub-stories:
- Story [N] → Story [Na]: [new title] + Story [Nb]: [new title] — reason: [why]

Criteria rewritten:
- Story [N], Criterion [X]: [original] → [rewritten version]

Priority adjustments:
- Story [N]: [P0 → P1] — reason: [why]

Revised MVP boundary (if changed):
- MVP: Stories [list]
- Post-MVP: Stories [list]

Then output the COMPLETE refined story list — every story in full, incorporating
all changes. Do not output only the changed stories — output the full final set.
```
Tools: Read

Gate: Print refinement summary (stories changed, criteria rewritten). Ask:
"Refinement complete. Proceed to FINALIZE TICKETS? [y/N]"

---

## Stage 3 — FINALIZE TICKETS

Spawn the `user-story-writer` agent. Pass the Stage 2 refined story list (first 3000 chars) as `{{REFINED_STORIES}}`.

Agent prompt:
```
You are the user-story-writer agent.

Feature: {{FEATURE}}
Ticket system: {{TICKET_SYSTEM}}
Story format: {{STORY_FORMAT}}
AC format: {{AC_FORMAT}}
Sprint length: {{SPRINT_LENGTH}}
Docs platform: {{DOCS_PLATFORM}}

Refined stories from Stage 2:
{{REFINED_STORIES}}

Your task: produce three outputs — ticket bodies, sprint plan, and grooming invite.

---

OUTPUT 1: FULL TICKET BODIES (for every MVP story)

For each MVP story, write the complete ticket body ready to copy-paste into
{{TICKET_SYSTEM}}. Use the platform's preferred formatting:

[For Jira — use Jira wiki markup:]
h3. Story
[story statement]

h4. Context
[context paragraph]

h4. Acceptance Criteria
[AC in {{AC_FORMAT}}]

h4. Edge Cases
[bullet list]

h4. Out of Scope
[bullet list]

h4. Dependencies
[list]

h4. Definition of Ready
[x] Story written in {{STORY_FORMAT}} format
[x] Acceptance criteria cover happy path, errors, edge cases
[x] Out of scope defined
[x] Dependencies identified
[x] Estimate: [N] [{{ESTIMATION_SCALE}}]
[ ] Design attached (if applicable)
[ ] API contract defined (if applicable)
[ ] Open questions resolved

[For Linear / GitHub / Shortcut — use markdown:]
## Story
[story statement]

### Context
[context paragraph]

### Acceptance Criteria
[AC in {{AC_FORMAT}}]

### Edge Cases
[bullet list]

### Out of Scope
[bullet list]

### Dependencies
[list]

### Definition of Ready
- [x] Story written in {{STORY_FORMAT}} format
- [x] AC covers happy path, errors, edge cases
- [x] Out of scope defined
- [x] Dependencies identified
- [x] Estimate: [N] [{{ESTIMATION_SCALE}}]
- [ ] Design attached (if applicable)
- [ ] API contract defined (if applicable)
- [ ] Open questions resolved

---

OUTPUT 2: SPRINT ASSIGNMENT PLAN

Assign stories to sprints based on the implementation sequence from Stage 1,
adjusted for dependencies identified in Stage 2.

Sprint 1 — Foundation ({{SPRINT_LENGTH}}):
Stories: [N, N, N]
Goal: [What a user can do at the end of Sprint 1 — user-centric outcome]
Rationale: [Why these stories go first]

Sprint 2 — Core Flow ({{SPRINT_LENGTH}}):
Stories: [N, N, N]
Goal: [What a user can do at the end of Sprint 2 that they could not do after Sprint 1]
Rationale: [Dependencies, parallel work opportunities]

Sprint 3+ — Polish and Post-MVP ({{SPRINT_LENGTH}}):
Stories: [N, N, N]
Goal: [What improves for users in Sprint 3]
Rationale: [Why these are deferred from MVP]

---

OUTPUT 3: GROOMING EMAIL / INVITE TEMPLATE

Subject: Backlog Grooming — [{{FEATURE}}] — [Date TBD]

Hi team,

I'm scheduling a grooming session for the [{{FEATURE}}] epic. Here's what to
review in advance:

Epic summary:
[2-sentence description of what we're building and why]

Stories ready for grooming:
[List MVP stories with one-line summaries and estimates]

Stories needing discussion:
[List any stories flagged "needs-refinement" with the open question]

Please come prepared to:
1. Confirm or adjust story estimates
2. Identify any technical risks or unknowns
3. Agree on sprint assignments for Sprint 1 stories

Attachments / links:
- Stories: [{{TICKET_SYSTEM}} link — to add]
- PRD: [to add]
- Design: [to add]

Please confirm your availability for [Date TBD].

[PM name — to fill]
```
Tools: Read

---

## Summary Report

After all three stages complete, print:

```
════════════════════════════════════════════════════════
  User Stories — {{FEATURE}}
════════════════════════════════════════════════════════
  [✓] Stage 1 — DECOMPOSED    Total: N stories (P0:N  P1:N  P2:N)
  [✓] Stage 2 — REFINED       N stories split/merged, N criteria rewritten
  [✓] Stage 3 — FINALIZED     Ticket bodies ready for {{TICKET_SYSTEM}}
════════════════════════════════════════════════════════

MVP stories:     [N] — [list story summaries]
Post-MVP stories:[N] — [list story summaries]

Sprint plan:
  Sprint 1 ([N stories]): [goal in one sentence]
  Sprint 2 ([N stories]): [goal in one sentence]
  Sprint 3+ ([N stories]): [goal in one sentence]

Next actions:
  [ ] Create tickets in {{TICKET_SYSTEM}} using Stage 3 ticket bodies
  [ ] Schedule grooming using Stage 3 email template
  [ ] Attach design files and PRD links to each ticket
  [ ] Confirm sprint assignments with engineering lead
════════════════════════════════════════════════════════
```

---

## Variables

- `{{FEATURE}}` = argument passed to this command
- `{{DECOMPOSITION_OUTPUT}}` = Stage 1 agent output (first 3000 chars)
- `{{REFINED_STORIES}}` = Stage 2 agent output (first 3000 chars)
- `{{STORY_FORMAT}}`, `{{AC_FORMAT}}`, `{{ESTIMATION_SCALE}}`, `{{TICKET_SYSTEM}}`,
  `{{SPRINT_LENGTH}}`, `{{PRD_APPROVERS}}`, `{{DOCS_PLATFORM}}` = from product.config.md / workflow.config.md
