# Scrum — Quick Reference

A reference for running Scrum ceremonies and using the `scrum-master` agent with a mobile engineering team.

---

## Ceremonies at a Glance

| Ceremony | When | Duration (2-week sprint) | Who |
|---|---|---|---|
| Sprint Planning | Day 1 | ≤4 hours | Whole team + PO |
| Daily Standup | Every day | 15 min | Dev team |
| Sprint Review / Demo | Last day | ≤2 hours | Team + stakeholders |
| Retrospective | Last day (after review) | ≤1.5 hours | Dev team (+ SM) |
| Backlog Refinement | Mid-sprint | ≤1 hour | Dev team + PO |

---

## Sprint Planning Quick Guide

```
1. PO presents top backlog items (refined + estimated)
2. Team discusses capacity: (days × devs × 0.7 focus factor)
3. Pull stories from top of backlog until capacity reached
4. Agree on sprint goal (one sentence)
5. Break stories into tasks if needed
6. Commit: "Can we do this?" — everyone nods
```

**Capacity formula:**
```
available_days × focus_factor(0.7) × developers = capacity in ideal days
multiply by average daily points to get point budget
```

**Rule:** Never commit >85% of capacity. Keep a buffer for unplanned bugs and meetings.

---

## Standup Format

```
✅ Done since last standup:   [specific ticket or task]
🔨 Doing until next standup: [specific ticket or task]
🚧 Blockers / risks:          [or "none"]
```

Keep to 2 minutes per person. Move detailed discussions offline immediately after.

**Blocker types:**
- `BLOCKER` — stops work completely → escalate same day
- `RISK` — may slow delivery → discuss at next planning
- `DEPENDENCY` — blocked by another team → assign a DRI and deadline

---

## Definition of Ready (DoR)

A story must have all of these before entering a sprint:

- [ ] Clear title and user story format
- [ ] Acceptance criteria (testable, not vague)
- [ ] Story points estimated by the team
- [ ] UI design / mockup attached (if visual change)
- [ ] API contract known (if backend dependency)
- [ ] Mobile scope explicit: Android / iOS / both
- [ ] Dependencies identified

---

## Definition of Done (DoD) — Mobile

- [ ] All acceptance criteria met and verified on device
- [ ] Unit tests written and passing
- [ ] UI / integration tests passing on CI
- [ ] Code reviewed and approved (≥1 reviewer)
- [ ] No new unresolved lint warnings
- [ ] Accessibility: content descriptions, touch targets ≥48dp/44pt
- [ ] No hardcoded strings or secrets
- [ ] Release notes entry written
- [ ] Merged to integration branch

---

## Retrospective Formats

### Start / Stop / Continue (default)
- **Start** — things we should begin doing
- **Stop** — things that slow us down
- **Continue** — things working well

### 4Ls
- **Liked** — what made you happy
- **Learned** — what you discovered
- **Lacked** — what was missing
- **Longed for** — what you wish had happened

### Sailboat
- **Wind** (accelerators) — what pushed us forward
- **Anchors** (blockers) — what held us back
- **Rocks** (risks) — dangers ahead
- **Sun** (goal) — what we're sailing toward

**Action item format:**
```
Action: [specific change]
Owner: @person
Due: [date or "next sprint"]
Jira: [ticket if created]
```

---

## Story Points — Fibonacci Scale

| Points | Meaning |
|---|---|
| 1 | Trivial — a config change, a copy fix |
| 2 | Small — well-understood, 1–2 hours |
| 3 | Medium-small — familiar work, half a day |
| 5 | Medium — some unknowns, ~1 day |
| 8 | Large — multiple unknowns, 2–3 days |
| 13 | Very large — needs breaking down |
| 21 | Epic-sized — split before committing |

**If the team argues >5 minutes on an estimate → split the story.**

---

## Velocity Tracking

```
Sprint velocity = story points completed (DoD met) in the sprint

Rolling average = last 3 sprints
Commitment = 85% of rolling average
```

**Signals to investigate:**
- Velocity drops >20% two sprints in a row → retro topic
- Commitment accuracy <70% consistently → planning or estimation problem
- Carry-over >20% → scope too aggressive or stories too large

---

## Sprint Health Signals

| Signal | Meaning | Action |
|---|---|---|
| >30% of points in "To Do" past midpoint | At risk | Descope with PO |
| Story unchanged for 3+ days | Stale / hidden blocker | Check in 1:1 |
| P1 bug opened mid-sprint | Unplanned work | Triage before next standup |
| Team adding scope mid-sprint | Sprint goal drift | Redirect to backlog |
| Multiple carry-overs same story | Story too large | Split before next sprint |

---

## Commands

```
/standup           Facilitate today's daily standup
/retro             Run a sprint retrospective
/sprint-health     Check sprint burndown and surface risks
/sprint-start [N]  Kick off a new sprint (syncs branches, prints checklist)
```

---

## Asking the Scrum Master Agent

```
"Run standup"
"What's at risk in this sprint?"
"Help me plan Sprint 48"
"Run a retro using the Sailboat format"
"What's our velocity for the last 3 sprints?"
"PROJ-123 has been blocked for 2 days — what should we do?"
"Is our DoD being met consistently?"
"Break down this epic into sprint-sized stories"
```
