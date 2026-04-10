---
description: Full backend SDLC pipeline for a new API feature. Stages: architect → develop → test → review → security → deploy-checklist.
---

Run a 6-stage backend SDLC pipeline for the requested feature.

## Stage 1 — ARCHITECT (backend-architect)

Spawn `backend-architect` with the feature description. Pass:
- Feature description
- Existing `backend.config.md` content (if present)

The architect produces: API contract, data model, service design.

## Stage 2 — DEVELOP (api-developer)

Spawn `api-developer` with:
- Stage 1 architecture output (first 3000 chars)
- Feature description

The developer produces: migration, domain model, repository, service, controller, initial tests.

## Stage 3 — TEST (backend-test-planner)

Spawn `backend-test-planner` with:
- Stage 2 implementation (file list and key code)
- Feature description

The test planner produces: unit tests, integration tests, test data factories.

## Stage 4 — REVIEW (api-reviewer)

Spawn `api-reviewer` with the file paths from Stage 2. The reviewer produces a structured review report.

## Stage 5 — SECURITY (backend-security) and Stage 6 — DEPLOY CHECKLIST

Spawn in parallel:
- `backend-security` — OWASP API Security Top 10 audit
- `devops-advisor` — deployment checklist for the new endpoint

## Final summary

After all stages complete, output:
1. Files created/modified
2. Review findings to address
3. Security findings to address
4. Deployment checklist
