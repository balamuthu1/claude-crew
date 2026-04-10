Review backend API code for correctness, code quality, database usage, and OWASP API Security Top 10. Argument is one or more file paths, a glob pattern, or a feature name.

You are the **orchestrator**. Do NOT review code yourself — spawn dedicated sub-agents for each stage using the `Agent` tool. Each sub-agent gets an isolated context window.

---

## Before starting

Read `backend.config.md` and `workflow.config.md`. Extract:
- `{{FILES}}` — argument passed to this command (file paths, glob, or feature name)
- `{{LANGUAGE}}` — e.g. `node` / `python` / `go` / `java`
- `{{FRAMEWORK}}` — e.g. `express` / `fastapi` / `gin` / `spring-boot`
- `{{ORM}}` — e.g. `prisma` / `sqlalchemy` / `gorm` / `hibernate`
- `{{DB}}` — e.g. `postgresql` / `mysql` / `mongodb`
- `{{AUTH_MECHANISM}}` — e.g. `jwt` / `session` / `oauth2` / `api-key`
- `{{API_STYLE}}` — `rest` | `graphql` | `grpc` | `trpc`
- `{{TICKET_SYSTEM}}` — from `workflow.config.md`
- `{{TEST_FRAMEWORK}}` — e.g. `jest` / `pytest` / `go-test`

If `backend.config.md` does not exist, note the gap and suggest running `/detect-backend-stack`, then continue with best-effort values inferred from any `package.json`, `requirements.txt`, `go.mod`, or `pom.xml` found.

If `{{FILES}}` is a feature name rather than file paths, use Glob to find matching
controller/handler/service/repository files before spawning Stage 1.

---

## Stage Definitions

### Stage 1 — CODE REVIEW
Spawn the `api-reviewer` agent.

Agent prompt:
```
You are the api-reviewer agent.

Files to review: {{FILES}}
Language: {{LANGUAGE}}
Framework: {{FRAMEWORK}}
ORM: {{ORM}}
Database: {{DB}}
Auth mechanism: {{AUTH_MECHANISM}}
API style: {{API_STYLE}}

Read backend.config.md and profiles/backend/rules/api-design.md and
profiles/backend/rules/database.md before reviewing.

Review every file listed. Apply the full checklist below.
Every finding requires a FILE:LINE reference. No general observations without location.

---

### Correctness checklist

**Request validation**
- [ ] All input fields validated before use — no trust of `req.body`, query params,
  or path parameters without schema validation (Zod, Joi, class-validator, Pydantic,
  go-validator, etc.)
- [ ] Validation errors return 400 with field-level error details (which field, why invalid)
- [ ] No client-supplied IDs used as database keys without existence + ownership check
- [ ] Array inputs have maximum length enforced (prevents DoS via huge payloads)
- [ ] String inputs have maximum length enforced
- [ ] Numeric inputs have range constraints where applicable

**Response shape consistency**
- [ ] All endpoints use the same success envelope (e.g. `{ data: ..., meta: ... }`)
- [ ] All error responses use the same error envelope (e.g. `{ error: { code, message, details } }`)
- [ ] No endpoint leaks internal field names (ORM model fields, DB column names) directly
- [ ] Timestamps returned in ISO 8601 / UTC — not Unix epoch integers unless documented

**HTTP semantics**
- [ ] GET endpoints are safe and idempotent (no side effects, no state change)
- [ ] POST creates a new resource and returns 201 with the created resource
- [ ] PUT replaces a resource fully; PATCH updates partially — not mixed
- [ ] DELETE returns 204 (no content) or 200 with deleted resource — consistent project-wide
- [ ] 400 used for client validation errors; 422 used for semantically invalid but
  well-formed requests (e.g. "end date before start date")
- [ ] 401 returned when unauthenticated (missing or invalid token)
- [ ] 403 returned when authenticated but not authorised for this resource
- [ ] 404 returned for not-found; never 200 with null body
- [ ] 409 returned for conflict (duplicate unique constraint violation)
- [ ] 500 never leaks stack trace or internal details to clients

**Idempotency**
- [ ] PUT and DELETE are idempotent (calling twice produces same result)
- [ ] POST mutations that can be retried (e.g. payment processing, email sending)
  have an idempotency key mechanism

**Pagination**
- [ ] All list/collection endpoints are paginated — no unbounded result sets
- [ ] Pagination style consistent (cursor-based preferred; offset acceptable if documented)
- [ ] Page size has a maximum cap enforced server-side (e.g. max 100)
- [ ] Total count or next-cursor included in response for client navigation

**Filtering and sorting**
- [ ] Filter and sort parameters validated against an allowlist of fields
  (prevent arbitrary column references reaching the DB query)
- [ ] Sort direction restricted to `asc` / `desc` — not interpolated as raw SQL

**Transaction boundaries**
- [ ] Any operation touching multiple tables / collections is wrapped in a transaction
- [ ] Partial-failure scenarios (e.g. insert succeeds but notification fails) handled
  correctly — rollback or idempotent retry
- [ ] Distributed operations (cross-service writes) use saga/outbox pattern if eventual
  consistency is acceptable, or synchronous two-phase if not

---

### Code quality checklist

**Layering**
- [ ] Controller / route handler is thin: only parse input, call service, format response
- [ ] Business logic lives in the service layer — not in route handlers or repositories
- [ ] Service layer does NOT import from HTTP layer (`req`, `res`, `ctx` objects must
  not appear in service function signatures)
- [ ] Repository / DAO isolates all database access — service layer never calls ORM directly
- [ ] Cross-cutting concerns (auth, logging, tracing) applied via middleware, not inline

**Error handling**
- [ ] Errors propagated as typed error classes (`NotFoundError`, `ValidationError`,
  `UnauthorizedError`) — not raw strings or generic `Error`
- [ ] Global error handler maps typed errors to HTTP status codes
- [ ] Database errors caught at the repository layer and translated to domain errors
  (never let ORM-specific error objects bubble up to the HTTP layer)
- [ ] Async functions / promises have error handling — no floating promises,
  no unhandled rejections

**Observability**
- [ ] Structured logging (JSON) at key events: request received, business event
  completed, error occurred
- [ ] Request / correlation ID propagated through all log lines in a request context
- [ ] No `console.log` / `print` / `fmt.Println` in production code paths — structured logger only
- [ ] Sensitive data (passwords, tokens, PII) never logged — even at DEBUG level
- [ ] Health check endpoint excluded from access log (prevents log noise)

**Configuration**
- [ ] No hardcoded URLs, ports, timeouts, or limits — use environment variables or config
- [ ] No hardcoded credentials, API keys, or connection strings (security issue → will
  also be flagged in Stage 2)
- [ ] Timeouts configured for all outbound HTTP calls (no default infinite timeout)

**Async correctness ({{LANGUAGE}}-specific)**
- For Node.js: no `await` inside `forEach` — use `Promise.all(array.map(...))` or `for...of`
- For Python: no `asyncio.run()` inside an already-running event loop
- For Go: goroutines properly bounded — no goroutine leaks; context cancellation respected
- For Java: thread pool sizes configured; CompletableFuture chained correctly

---

### Database checklist ({{DB}} via {{ORM}})

**Query efficiency**
- [ ] No queries inside loops — N+1 pattern: if a loop calls the DB per iteration,
  rewrite as a batch/join query
- [ ] `SELECT *` never used — only select columns the caller needs
- [ ] Large result sets streamed or paginated, not loaded entirely into memory
- [ ] `.findAll()` / equivalent without a `WHERE` clause on a table that may grow large

**Index coverage**
- [ ] Every column used in `WHERE`, `JOIN ON`, or `ORDER BY` has an index
- [ ] Composite indexes ordered by selectivity (most selective column first)
- [ ] No function applied to an indexed column in WHERE clause (defeats index):
  e.g. `WHERE LOWER(email) = ...` → add a functional index or store lowercase

**Migration safety**
- [ ] No `DROP COLUMN` on a table with active traffic without a multi-step migration plan
- [ ] No `NOT NULL` constraint added to an existing column without a default or backfill
- [ ] No table rename in a single migration (zero-downtime requires dual-write period)
- [ ] Migration has a rollback (`down`) path
- [ ] Migration does not hold a table-level lock for more than a few seconds on large tables

**Connection management**
- [ ] Connection pool used — no new connection created per request
- [ ] Pool size configured appropriately (not unbounded)
- [ ] Connections always released back to pool in all code paths (no leak on error)

---

### Output format

## API Code Review — {{FILES}}

### Critical (security risk, data loss, incorrect behaviour — block merge)
- [FILE:LINE] **Issue title** — Impact explanation — Exact fix required

### Major (performance, reliability, or maintainability gap — fix before release)
- [FILE:LINE] **Issue title** — Explanation — Fix

### Minor (style, naming, documentation — fix in follow-up)
- [FILE:LINE] Suggestion

### Approved patterns (good practices worth noting)
- [FILE:LINE] Description of good practice

### Review summary
- Critical: N | Major: N | Minor: N
- Merge recommendation: BLOCK / CONDITIONAL (fix Critical+Major) / APPROVE

Tools: Read, Grep, Glob
```

Gate: Print the review summary line (Critical/Major/Minor counts and merge recommendation). Ask:

```
Code review complete — Critical: N, Major: N, Minor: N.  Recommendation: [BLOCK/CONDITIONAL/APPROVE]
Proceed to SECURITY AUDIT? [y/N]
```

Wait for user confirmation before continuing.

---

### Stage 2 — SECURITY AUDIT
Spawn the `backend-security` agent.

Agent prompt:
```
You are the backend-security agent performing an OWASP API Security Top 10 (2023) audit.

Files to audit: {{FILES}}
Language: {{LANGUAGE}}
Framework: {{FRAMEWORK}}
Auth mechanism: {{AUTH_MECHANISM}}
Database: {{DB}}

Read profiles/backend/rules/backend-security-guardrails.md before starting.
Every finding requires a FILE:LINE reference and a working remediation code example.

---

### API1:2023 — Broken Object Level Authorization
For every endpoint that accepts a resource identifier (path param, query param, body ID):
- [ ] The handler verifies the authenticated caller owns or has access to that resource
  before returning or modifying it
- [ ] No IDOR: sequential integer IDs exposed to clients allow enumeration — flag any
  endpoint that accepts `id=123` style integers for sensitive resources (use UUIDs)
- [ ] Bulk endpoints (e.g. `GET /users?ids=1,2,3`) verify each ID in the list

### API2:2023 — Broken Authentication
- [ ] Auth token validated on EVERY authenticated endpoint — no route that should
  require auth but lacks the auth middleware
- [ ] JWT: algorithm explicitly specified and allowlisted (no `alg: none` accepted),
  signature verified, `exp` claim checked
- [ ] API keys: constant-time comparison used to prevent timing attacks
  (`crypto.timingSafeEqual` in Node.js, `hmac.compare` in Python, etc.)
- [ ] Session fixation: session ID regenerated after successful login
- [ ] Brute force: auth endpoints (`/login`, `/token`, `/password-reset`) have rate limiting

### API3:2023 — Broken Object Property Level Authorization
- [ ] Mass assignment: request body not spread or assigned directly to ORM model
  (e.g. no `Object.assign(user, req.body)` — use explicit field mapping)
- [ ] Response filtering: sensitive fields stripped from responses — flag any endpoint
  that might return: `password`, `password_hash`, `secret`, `token`, `salt`,
  `ssn`, `credit_card`, `cvv`, `private_key`
- [ ] Admin-only fields (e.g. `role`, `is_admin`, `balance`) not writable via
  regular user endpoints

### API4:2023 — Unrestricted Resource Consumption
- [ ] Rate limiting applied to all endpoints (general) and tighter limits on:
  expensive operations, auth endpoints, file uploads, bulk operations
- [ ] File upload: file size limit enforced; file type validated (not just extension)
- [ ] Request body size limit configured at the framework/middleware level
- [ ] Query parameters that affect result set size (e.g. `limit`, `page_size`)
  capped server-side regardless of client request
- [ ] Recursive or deeply nested operations bounded (e.g. max tree depth)

### API5:2023 — Broken Function Level Authorization
- [ ] Admin endpoints (any route under `/admin`, `/internal`, `/management`) require
  an admin role check — not just authentication
- [ ] Different user tiers (free / pro / admin) cannot access each other's privileged
  operations even if they know the URL
- [ ] Sensitive operations (delete account, change email, change password) require
  re-authentication or current password confirmation

### API6:2023 — Unrestricted Access to Sensitive Business Flows
- [ ] High-value flows (checkout, registration, password reset, voucher redemption,
  referral bonus) protected against automated abuse:
  - Rate limiting per user and per IP
  - Require authenticated session (not just a token)
  - Consider CAPTCHA or proof-of-work for unauthenticated entry points
- [ ] Quantity limits enforced on resource-creating operations (e.g. max 10 active
  API keys per user, max 100 items in a cart)

### API7:2023 — Server Side Request Forgery (SSRF)
- [ ] Any endpoint that fetches a URL supplied (directly or indirectly) by the client
  validates the URL against an allowlist of domains or blocks private/reserved IPs:
  `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`, `127.0.0.0/8`, `169.254.0.0/16`
- [ ] Webhooks registered by users are validated before first delivery (head request
  to the URL to confirm it responds) and blocked if they resolve to internal addresses
- [ ] URL redirect parameters (`?next=`, `?redirect=`) validated to prevent open redirect

### API8:2023 — Security Misconfiguration
- [ ] CORS `Access-Control-Allow-Origin` not set to `*` for authenticated endpoints —
  must be an explicit allowlist of trusted origins
- [ ] Stack traces, internal file paths, ORM query details, or database errors never
  included in client error responses
- [ ] HTTP security response headers present (check middleware or framework defaults):
  `Strict-Transport-Security`, `X-Content-Type-Options: nosniff`,
  `X-Frame-Options: DENY`, `Referrer-Policy: no-referrer`
- [ ] Debug mode / development endpoints not reachable in production
  (e.g. `/debug`, `/console`, `/__debug__`, Swagger UI in prod without auth)
- [ ] Default credentials changed; no test accounts in production code

### API9:2023 — Improper Inventory Management
- [ ] No deprecated API versions still accepting traffic in production without
  documented sunset date and client migration plan
- [ ] No test or temporary endpoints reachable in production
  (e.g. `/test`, `/echo`, `/ping` that returns full request details)
- [ ] All active routes documented in OpenAPI / API catalog

### API10:2023 — Unsafe Consumption of APIs
- [ ] All outbound HTTP calls have explicit timeouts configured (connect + read timeout)
- [ ] Responses from third-party APIs validated before use — no blind
  `JSON.parse(response)` and field access without schema validation
- [ ] Third-party API errors handled gracefully — not allowed to propagate as 500s
- [ ] Credentials for downstream services stored in secrets manager ({{SECRETS_MANAGER}}),
  not in code or `.env` files committed to the repository

---

### Output format

## Security Audit — {{FILES}}

### Critical (exploitable vulnerability — block merge immediately)
- [FILE:LINE] **OWASP API#N** — Severity: Critical — Description — Working fix

### High (significant security gap — fix before release)
- [FILE:LINE] **OWASP API#N** — Severity: High — Description — Fix

### Medium (defense-in-depth improvement)
- [FILE:LINE] **OWASP API#N** — Severity: Medium — Description — Recommendation

### Passed checks
- OWASP API#N — Description of compliant implementation

### Security summary
- Critical: N | High: N | Medium: N
- Merge recommendation: BLOCK / CONDITIONAL / PASS

Tools: Read, Grep, Glob
```

Gate: Print the security audit summary line. Ask:

```
Security audit complete — Critical: N, High: N, Medium: N.  Recommendation: [BLOCK/CONDITIONAL/PASS]
Proceed to ACTION PLAN? [y/N]
```

Wait for user confirmation before continuing.

---

### Stage 3 — ACTION PLAN
Spawn the `api-reviewer` agent.

Agent prompt:
```
You are the api-reviewer agent producing a consolidated action plan.

Files reviewed: {{FILES}}
Ticket system: {{TICKET_SYSTEM}}

Code review findings (Stage 1):
{{REVIEW_OUTPUT}}

Security audit findings (Stage 2):
{{SECURITY_OUTPUT}}

Produce the following:

### 1. Consolidated critical and major findings
Combine all Critical and High findings from both stages into a single prioritised list.
For each finding:
- ID: CR-N (code review) or SEC-N (security)
- Severity: Critical / High
- Location: FILE:LINE
- One-sentence description
- Exact fix (code snippet if < 10 lines; description of approach if larger)

### 2. Ticket creation instructions
For each Critical and High finding, provide the exact ticket to create in {{TICKET_SYSTEM}}:

**If {{TICKET_SYSTEM}} is jira:**
  Project: [from jira.config.md → jira_project_key]
  Issue type: Bug (security findings) / Task (code quality findings)
  Summary: "[CR/SEC-N] [one-line description]"
  Priority: Blocker (Critical) / High (High)
  Labels: api-review, security (for SEC findings), backend
  Description:
    h3. Problem
    [2–3 sentences describing the issue and its impact]
    h3. Location
    {{FILES}} — line N
    h3. Fix
    [exact remediation or code snippet]
    h3. Acceptance criteria
    - [ ] Fix applied and unit tested
    - [ ] Reviewed by a second engineer
    - [ ] Security finding: confirm with security team if Critical

**If {{TICKET_SYSTEM}} is linear:**
  Team: Engineering
  Title: "[CR/SEC-N] [one-line description]"
  Priority: Urgent (Critical) / High (High)
  Labels: api-review, security
  Description: [same structure as above in markdown]

**If {{TICKET_SYSTEM}} is github-issues:**
  Title: "[CR/SEC-N] [one-line description]"
  Labels: bug (security) / enhancement (quality), priority:critical or priority:high
  Body: [markdown with Problem / Location / Fix / Acceptance criteria sections]

### 3. Safe-to-merge verdict
State clearly:
- BLOCKED: one or more Critical findings must be resolved before merge
- CONDITIONAL: all Critical fixed, Major findings documented as follow-up tickets
- APPROVED: no Critical or Major findings

Tools: Read
```

After all three stages complete, print the combined summary report:

```
════════════════════════════════════════════════════════
  API Review — {{FILES}}
════════════════════════════════════════════════════════
  [✓] Stage 1 — CODE REVIEW    Critical: N, Major: N, Minor: N
  [✓] Stage 2 — SECURITY       Critical: N, High: N, Medium: N
  [✓] Stage 3 — ACTION PLAN    Tickets to create: N
════════════════════════════════════════════════════════

Overall verdict: [BLOCKED / CONDITIONAL / APPROVED]

Tickets to create in {{TICKET_SYSTEM}}:
  Critical / Blocker:
    - [CR/SEC-N] [one-line summary per finding]
  High:
    - [CR/SEC-N] [one-line summary per finding]

Next steps:
  [ ] Fix all Critical findings
  [ ] Create tickets for Major/High findings
  [ ] Re-run review on fixed files before merge
```

---

## Variables

- `{{FILES}}` = argument passed to this command (file paths, glob, or feature name)
- `{{LANGUAGE}}` = from `backend.config.md` → `language`
- `{{FRAMEWORK}}` = from `backend.config.md` → `framework`
- `{{ORM}}` = from `backend.config.md` → `orm`
- `{{DB}}` = from `backend.config.md` → `database_primary`
- `{{AUTH_MECHANISM}}` = from `backend.config.md` → `auth_strategy`
- `{{API_STYLE}}` = from `backend.config.md` → `api_style`
- `{{TEST_FRAMEWORK}}` = from `backend.config.md` → `test_framework`
- `{{TICKET_SYSTEM}}` = from `workflow.config.md` → `ticket_system`
- `{{REVIEW_OUTPUT}}` = Stage 1 output (first 3000 chars)
- `{{SECURITY_OUTPUT}}` = Stage 2 output (first 3000 chars)
