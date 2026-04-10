Run a full backend SDLC pipeline for the API feature described in the argument.

You are the **orchestrator**. Do NOT implement any stage yourself — spawn a dedicated
sub-agent for each stage using the `Agent` tool. Each sub-agent gets an isolated context
window focused on its domain.

---

## How to Orchestrate

For every stage call the `Agent` tool with:
- `description`: the stage label
- `prompt`: built from the template below (inject feature + prior stage output)

**For stages 5 and 6 (security + deploy): call `Agent` twice in a single message to run them in parallel.**

After all stages complete, print the SDLC Summary Report.

---

## Stage Definitions

### Stage 1 — ARCHITECT
Spawn the `backend-architect` agent.

Agent prompt:
```
You are the backend-architect agent.

Feature: {{FEATURE}}

Read backend.config.md first (language, framework, ORM, auth pattern). Then produce:
1. API contract — HTTP method, URL path, request/response schemas, status codes
2. Data model — entity fields, types, constraints, relationships
3. Service boundary design — what this service owns, what it delegates
4. Database access pattern — new tables/columns needed, queries, indices
5. Auth/authorisation requirements — which roles can call this endpoint
6. File/directory structure — real paths for every file to be created

Output a concrete plan the api-developer can implement from immediately.
No pseudocode. Include actual field names, types, and HTTP status codes.
```
Tools to allow: Read, Glob

Gate: Print the API contract and data model. Ask "Proceed to DEVELOP? [y/N]"

---

### Stage 2 — DEVELOP
Spawn the `api-developer` agent.

Agent prompt:
```
You are the api-developer agent.

Feature: {{FEATURE}}

Architecture from Stage 1:
{{ARCH_OUTPUT}}

Read backend.config.md first, then implement the full feature in this order:

1. Database migration — up + down, safe for production (no table locks on large tables)
2. Domain model / entity — field types, validation constraints
3. Repository interface — define the contract
4. Repository implementation — ORM queries, error mapping
5. Service layer — business logic, transaction boundaries, error cases
6. Controller / route handler — input validation, HTTP response codes, error responses
7. DTO / request-response types — separate from domain model
8. Dependency injection / DI wiring

Write complete, production-quality code. No pseudocode. No TODOs.
Follow the conventions in backend.config.md for the project's framework.

Security: parameterised queries only, no string concatenation, no hardcoded credentials.
```
Tools to allow: Read, Write, Edit, Glob, Bash

Gate: Show list of files created/modified. Ask "Proceed to TEST? [y/N]"

---

### Stage 3 — TEST
Spawn the `backend-test-planner` agent.

Agent prompt:
```
You are the backend-test-planner agent.

Feature: {{FEATURE}}

Implementation from Stage 2:
{{BUILD_OUTPUT}}

Read backend.config.md for the test framework. Then write:

**Unit tests (service layer):**
- Happy path: valid input → expected output
- Not found: resource doesn't exist → correct error
- Validation error: invalid input → validation exception
- Permission denied: wrong user → authorisation exception
- External service failure: downstream error → graceful handling

**Integration tests (API layer):**
- POST /endpoint with valid body → 201 + correct response shape
- POST with invalid body → 400 + field-level error details
- GET without auth → 401
- GET authenticated but wrong user's resource → 403
- GET non-existent resource → 404
- Full round-trip: create then fetch → data matches

Use real database in integration tests with transaction rollback.
Use test doubles (mocks/stubs) in unit tests — no real database or network.

Write complete test files with imports, setup, teardown, and all test cases.
```
Tools to allow: Read, Write, Edit, Glob

Gate: Show test file list and case count. Ask "Proceed to REVIEW? [y/N]"

---

### Stage 4 — CODE REVIEW
Spawn the `api-reviewer` agent.

Agent prompt:
```
You are the api-reviewer agent.

Feature: {{FEATURE}}

Review all code from the build stage. Apply rules from:
- profiles/backend/rules/api-design.md
- profiles/backend/rules/database.md

Files to review:
{{BUILD_OUTPUT}}

Output format:
## API Code Review

### Critical (block merge)
- [FILE:LINE] Issue — Why it matters — Exact fix

### Major (fix before release)
- [FILE:LINE] Issue — Why — Fix

### Minor (improvements)
- [FILE:LINE] Suggestion

### Approved patterns
- [FILE:LINE] Noteworthy good practice

Be specific — file:line references required for every finding.
```
Tools to allow: Read, Grep, Glob

Gate: If Critical issues found, list them. Ask "Issues found. Proceed anyway? [y/N]"

---

### Stage 5 — SECURITY  ← spawn in PARALLEL with Stage 6
Spawn the `backend-security` agent.

Agent prompt:
```
You are the backend-security agent.

Feature: {{FEATURE}}

Audit the code from the build stage against OWASP API Security Top 10.

Files to audit:
{{BUILD_OUTPUT}}

For EACH finding provide:
- OWASP API #N reference
- FILE:LINE location
- Severity: Critical / High / Medium / Low
- Working remediation code (not just description)

Check specifically:
1. Object-level authorisation — does every endpoint verify the caller owns the resource?
2. Auth implementation — token validation, expiry check, refresh logic
3. Input validation — all fields validated, size limits, type coercion
4. Rate limiting — auth endpoints, expensive operations
5. SQL injection — any string concatenation in queries?
6. Sensitive data in responses — are passwords/tokens ever returned?
7. CORS configuration — is it wildcard in production?
8. Secrets in code — any hardcoded credentials, API keys, connection strings?
9. Error responses — do they leak stack traces or internal details?
10. Mass assignment — do response DTOs expose fields that shouldn't be exposed?

Read profiles/backend/rules/backend-security-guardrails.md before starting.
```
Tools to allow: Read, Grep, Glob

---

### Stage 6 — DEPLOY READINESS  ← spawn in PARALLEL with Stage 5
Spawn the `devops-advisor` agent.

Agent prompt:
```
You are the devops-advisor agent.

Feature: {{FEATURE}}

A new API endpoint has been built. Review the deployment readiness.

Files created:
{{BUILD_OUTPUT}}

Produce a deployment checklist:

**Migration safety:**
- [ ] Migration is non-destructive (no drops, no NOT NULL without default on large tables)
- [ ] Migration has a down/rollback path
- [ ] Migration runs before new pods start (init container or pre-deploy hook)

**Runtime safety:**
- [ ] Health check endpoint returns 200 when DB is reachable
- [ ] Liveness + readiness probes configured
- [ ] Resource limits set (CPU + memory)
- [ ] Graceful shutdown: in-flight requests complete before shutdown

**Observability:**
- [ ] New endpoint emits request count + latency metrics
- [ ] Errors are logged with context (no raw stack traces to stdout)
- [ ] Distributed trace spans added for DB calls

**Security:**
- [ ] Secrets injected via env vars or secrets manager (not hardcoded)
- [ ] Service account has minimal permissions

List any blockers and suggest fixes.
```
Tools to allow: Read, Grep, Glob

After both Stage 5 and Stage 6 complete, print their combined findings.
Gate: Ask "Proceed to final summary? [y/N]"

---

## SDLC Summary Report

After all stages complete, print:

```
════════════════════════════════════════════════════════
  Backend SDLC Report — {{FEATURE}}
════════════════════════════════════════════════════════
  [✓] Stage 1 — ARCHITECT     API: [METHOD /path]
  [✓] Stage 2 — DEVELOP       Files: [N files created]
  [✓] Stage 3 — TEST          Tests: [N unit, M integration]
  [✗] Stage 4 — REVIEW        Blockers: [list if any]
  [✓] Stage 5 — SECURITY      Findings: [N critical, M high]
  [✓] Stage 6 — DEPLOY        Blockers: [list if any]
════════════════════════════════════════════════════════

Open items:
- [ ] [Any unresolved issues from review/security]

Validation commands:
  Run tests:    <framework test command from backend.config.md>
  Run linter:   <linter from backend.config.md>
  Check types:  <type checker if applicable>
```

---

## Variables

- `{{FEATURE}}` = argument passed to this command
- `{{ARCH_OUTPUT}}` = Stage 1 output (first 3000 chars)
- `{{BUILD_OUTPUT}}` = Stage 2 output listing file paths created (first 3000 chars)
