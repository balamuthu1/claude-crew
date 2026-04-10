# Scrum Rules — Claude Crew

These rules govern how the `scrum-master` agent and Scrum-related commands behave.
All agents read `jira.config.md` and `git-flow.config.md` for team-specific context.

---

## Core Scrum Principles

- **Transparency**: all sprint work, blockers, and risks must be visible to the team
- **Inspection**: regularly check progress against the sprint goal and quality standards
- **Adaptation**: adjust the plan when reality diverges — do not protect a plan at the cost of the goal
- **Time-boxing**: every ceremony has a fixed duration; do not overrun
- **Pull system**: team members pull work; work is never pushed onto individuals

---

## Ceremonies

### Sprint Planning

**Input required before planning:**
- Refined and estimated backlog items (stories with acceptance criteria + points)
- Team capacity (available days minus PTO, holidays, meetings)
- Velocity from last 3 sprints
- Previous sprint leftover (carry-over stories)

**Output:**
- Sprint goal (one sentence: what value will the user get?)
- Sprint backlog (committed stories + tasks)
- Capacity vs committed points comparison

**Rules:**
- Do not plan more than 85% of capacity (buffer for unplanned work)
- Every committed story must have acceptance criteria
- Every committed story must be independently deliverable (no half-stories)
- Flag dependencies between stories before committing
- Identify if any story needs a Spike first

---

### Daily Standup

**Format (per person, max 2 minutes):**
1. What did I complete since last standup?
2. What will I complete before next standup?
3. Any blockers or risks?

**Rules:**
- Standup is for synchronisation, not status reporting to management
- Blockers are raised here; resolution happens after, in a separate conversation
- If someone is stuck >1 day on the same item, flag it immediately
- Unplanned work (bugs, incidents) must be added to the sprint board before the next standup

**Blocker classification:**
- `BLOCKER` — stops the story completely (escalate same day)
- `RISK` — may slow the story (discuss in next planning)
- `DEPENDENCY` — blocked by another team or service (assign a DRI)

---

### Sprint Review / Demo

**Format:**
- Show working software against each acceptance criterion
- No slides for the demo itself — live app or recording only
- Stakeholders can ask questions; scope changes go to the backlog, not mid-sprint

**Definition of Done checklist (mobile):**
- [ ] Acceptance criteria met and verified on device
- [ ] Unit tests written and passing (target coverage maintained)
- [ ] UI tests passing on CI
- [ ] Code reviewed and approved
- [ ] Accessibility audit passed (content descriptions, touch targets)
- [ ] No new lint warnings or suppressed warnings without justification
- [ ] No hardcoded strings, secrets, or API keys
- [ ] Release notes entry written
- [ ] Merged to the integration branch (develop / main)

---

### Retrospective

**Format (default: Start / Stop / Continue):**
- **Start**: things we should begin doing
- **Stop**: things that are slowing us down
- **Continue**: things working well that we should protect

**Alternative formats:**
- **4Ls**: Liked, Learned, Lacked, Longed For
- **Mad / Sad / Glad**
- **Sailboat**: Wind (accelerators), Anchors (blockers), Rocks (risks), Sun (goal)

**Rules:**
- All feedback is about processes and systems, never about individuals
- Every retro must produce at least one actionable improvement
- Action items become Jira tasks assigned to a DRI with a due date
- Review previous retro actions before collecting new feedback (did we follow through?)

**Anti-patterns to flag:**
- "We just need to work harder" → not an action item
- Action items with no owner → will not happen
- Same issues appearing in 3+ consecutive retros → escalate to leadership

---

## Artefacts

### Product Backlog

- Items are ordered by value × risk (highest value, highest risk first)
- All items have a title, description, and acceptance criteria before refinement
- Only the Product Owner (or their designate) may re-order the backlog
- Items estimated at >13 points must be split before sprint commitment

### Sprint Backlog

- Owned by the Development Team
- Updated daily (status transitions, remaining time/points)
- New unplanned work is added with the team's explicit agreement
- Items are never removed mid-sprint without team consensus and PO approval

### Increment

- Every sprint must produce a potentially shippable increment
- "Done" means the DoD is met — not "code is written"
- Mobile increments must pass CI, device testing, and accessibility check

---

## Metrics to Track

| Metric | How to measure | Healthy range |
|---|---|---|
| **Velocity** | Story points completed per sprint | Stable ±20% over 3 sprints |
| **Commitment accuracy** | Points delivered / points committed | 80–100% |
| **Carry-over rate** | Stories not finished / stories committed | <20% |
| **Blocker resolution time** | Hours from blocker raised to resolved | <24h for BLOCKER |
| **Bug injection rate** | New bugs per sprint vs stories delivered | Decreasing trend |
| **DoD pass rate** | Stories passing DoD on first review | >90% |

---

## Definition of Ready (DoR)

A story is ready to be pulled into a sprint when:

- [ ] Title is clear and unambiguous
- [ ] User story format: "As a [user], I want [action] so that [benefit]"
- [ ] Acceptance criteria written (testable, not open-ended)
- [ ] Story points estimated by the team
- [ ] Dependencies identified and resolved (or dependency noted)
- [ ] Design / mockup attached if UI is involved
- [ ] API contract known if backend work is involved
- [ ] Mobile scope clear: Android only / iOS only / both

---

## Scrum Master Anti-Patterns to Flag

| Anti-pattern | What to say |
|---|---|
| Sprint goal changes mid-sprint | "Scope changes go to the backlog. Shall we discuss priority for next sprint?" |
| No sprint goal defined | "Let's agree on one sentence: what value does this sprint deliver?" |
| Standup becomes a status meeting | "Let's take this offline — standup is for sync, not reporting." |
| Stories estimated alone by one person | "Estimates should be a team conversation — groupthink is the risk." |
| Retro without action items | "What's one thing we'll actually change before next retro?" |
| Velocity used as a productivity metric | "Velocity is a planning tool, not a performance measure." |
| Team skipping retro due to time pressure | "Skipping retro under pressure is exactly when it matters most." |

---

## Mobile-Specific Scrum Considerations

- **Release train alignment**: if you ship on a fixed App Store / Play Store cadence, the sprint goal must always produce a shippable build — even if it is not submitted
- **Feature flags**: unreleased code behind flags counts as "done" only if the flag infrastructure itself is tested
- **Carry-over due to review rejection**: App Store / Play Store rejections are unplanned — add a buffer story in planning
- **Platform parity**: Android and iOS stories for the same feature should be in the same sprint or have an explicit parity plan
- **Crash rate**: a spike in production crashes should trigger an unplanned bug story before the next sprint starts
