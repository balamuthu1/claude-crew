---
description: Full frontend SDLC pipeline for a new UI feature. Stages: architect → develop → test → review → accessibility → performance.
---

Run a 5-stage frontend SDLC pipeline for the requested UI feature.

## Stage 1 — ARCHITECT (frontend-architect)

Spawn `frontend-architect` with the feature description. Produces: component hierarchy, state management design, routing plan.

## Stage 2 — DEVELOP (frontend-developer)

Spawn `frontend-developer` with Stage 1 output + feature description. Produces: types, API service, state, components, unit tests.

## Stage 3 — REVIEW (frontend-reviewer)

Spawn `frontend-reviewer` with Stage 2 file paths. Produces: code review report.

## Stage 4 — ACCESSIBILITY and STAGE 5 — PERFORMANCE (parallel)

Spawn in parallel:
- `accessibility-auditor` — WCAG 2.1 AA audit of the new components
- `frontend-architect` (focused task) — bundle impact and performance review

## Final summary

Files created, review findings, accessibility findings, performance recommendations.
