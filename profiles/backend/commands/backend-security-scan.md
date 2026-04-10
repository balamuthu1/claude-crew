Run a dedicated security scan of backend code: secret detection, vulnerability analysis, and a remediation report with CWE/OWASP references and ticket instructions. Argument is a directory path or `full` for the entire codebase.

You are the **orchestrator**. Do NOT scan code yourself — spawn dedicated sub-agents for each stage using the `Agent` tool. Each sub-agent gets an isolated context window.

---

## Before starting

Read `backend.config.md` and `workflow.config.md`. Extract:
- `{{TARGET}}` — argument passed to this command (directory path or `full`)
- `{{LANGUAGE}}` — e.g. `node` / `python` / `go` / `java` / `ruby`
- `{{FRAMEWORK}}` — e.g. `express` / `fastapi` / `gin` / `spring-boot`
- `{{DB}}` — e.g. `postgresql` / `mysql` / `mongodb`
- `{{CLOUD}}` — e.g. `aws` / `gcp` / `azure` / `other`
- `{{SECRETS_MANAGER}}` — e.g. `aws-secrets` / `gcp-secret-manager` / `hashicorp-vault` / `env-file` / `none`
- `{{AUTH_MECHANISM}}` — e.g. `jwt` / `session` / `oauth2`
- `{{TICKET_SYSTEM}}` — from `workflow.config.md`

If `{{TARGET}}` is `full`, scan from the project root. Otherwise scope all searches to the specified directory.

If `backend.config.md` does not exist, note the gap and suggest running `/detect-backend-stack`, then continue by inferring the language from file extensions in `{{TARGET}}`.

---

## Stage Definitions

### Stage 1 — SECRET DETECTION
Spawn the `backend-security` agent.

Agent prompt:
```
You are the backend-security agent performing secret detection.

Target directory: {{TARGET}}
Language: {{LANGUAGE}}
Secrets manager in use: {{SECRETS_MANAGER}}

Read rules/security-guardrails.md and profiles/backend/rules/backend-security-guardrails.md
before starting.

IMPORTANT: When you find a secret, report its LOCATION (file path, line number) and
the PATTERN that matched. Do NOT output the actual secret value in your report.
Redact it as [REDACTED] in any output.

Run the following Grep searches. For every match report: file path, line number,
pattern that matched, and severity. Redact the matched value.

---

### 1.1 Hardcoded passwords
Pattern: assignment of a non-empty string literal to a key named password/passwd/pwd

Search for:
- `password\s*[=:]\s*["'][^"']{3,}["']` in all source files
- `passwd\s*[=:]\s*["'][^"']{3,}["']`
- `pwd\s*[=:]\s*["'][^"']{3,}["']`

Exclude: test fixtures and mock files (`*.test.*`, `*.spec.*`, `__tests__/`,
`testdata/`, `fixtures/`, `mocks/`) — flag these separately as lower severity.

### 1.2 Hardcoded API keys and tokens
Pattern: assignment of a string 16+ characters to a key containing "key", "token",
"secret", or "apikey":

- `api_key\s*[=:]\s*["'][^"']{16,}["']` (case-insensitive)
- `apikey\s*[=:]\s*["'][^"']{16,}["']`
- `access_token\s*[=:]\s*["'][^"']{16,}["']`
- `auth_token\s*[=:]\s*["'][^"']{16,}["']`
- `secret\s*[=:]\s*["'][^"']{20,}["']` (20+ chars to reduce noise)
- `bearer\s+[A-Za-z0-9\-._~+\/]+=*` (literal Bearer tokens in code)

### 1.3 JWT secrets
- `jwt.*secret\s*[=:]\s*["'][^"']{8,}["']` (case-insensitive)
- `JWT_SECRET\s*[=:]\s*["'][^"']{8,}["']`
- `jwtSecret\s*=\s*["'][^"']{8,}["']`

### 1.4 Database connection strings with credentials
Patterns that contain credentials inline (exclude localhost/127.0.0.1 test configs):
- `postgresql://[^:]+:[^@]+@` — Postgres URI with user:pass
- `postgres://[^:]+:[^@]+@`
- `mysql://[^:]+:[^@]+@`
- `mongodb\+srv://[^:]+:[^@]+@`
- `mongodb://[^:]+:[^@]+@`
- `redis://:[^@]+@` — Redis with password

Exclude lines containing `localhost`, `127.0.0.1`, `example.com`, `<password>`,
`${`, `process.env`, `os.environ`, `os.Getenv` — these are using env vars, not hardcoded.

### 1.5 Cloud provider credentials
AWS:
- `AKIA[0-9A-Z]{16}` — AWS Access Key ID pattern
- `aws_access_key_id\s*[=:]\s*["']?[A-Z0-9]{20}["']?`
- `aws_secret_access_key\s*[=:]\s*["']?[A-Za-z0-9/+=]{40}["']?`

GCP:
- `"type"\s*:\s*"service_account"` inside a JSON file (likely a service account key)
- `"private_key"\s*:\s*"-----BEGIN` in any JSON file

Azure:
- `AccountKey=[A-Za-z0-9+/=]{88}` — Azure Storage connection string

### 1.6 Private key material
- `-----BEGIN (RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----`
- `-----BEGIN CERTIFICATE-----` (may be intentional — flag as info, not critical)
- `PuTTY-User-Key-File`

### 1.7 Webhook and integration tokens
- `xox[baprs]-[0-9A-Za-z\-]{24,}` — Slack tokens
- `hooks\.slack\.com/services/T[A-Z0-9]+/B[A-Z0-9]+/`
- `discord\.com/api/webhooks/[0-9]+/[A-Za-z0-9\-_]+`
- `ghp_[A-Za-z0-9]{36}` — GitHub Personal Access Token
- `github_pat_[A-Za-z0-9_]{82}` — GitHub fine-grained PAT
- `sk-[A-Za-z0-9]{48}` — OpenAI API key pattern

### 1.8 .env file analysis
Glob for `.env`, `.env.local`, `.env.production`, `.env.staging` files.
If any exist OUTSIDE a gitignore-excluded directory:
- Flag as Critical: env files should never be committed
- List the file paths (do NOT read or output their contents)
- Check `.gitignore` to confirm they are excluded

---

### Output format

## Secret Detection Report — {{TARGET}}

### Critical (real secrets in committed code)
- [FILE:LINE] Pattern matched: [PATTERN NAME] — Value: [REDACTED] — Action: rotate immediately

### High (secrets in test fixtures or example files — lower risk but should use placeholders)
- [FILE:LINE] Pattern matched: [PATTERN NAME] — File type: test/fixture — Action: replace with placeholder

### Info (cert files or non-sensitive patterns)
- [FILE:LINE] Pattern matched: [PATTERN NAME] — Notes

### .env file findings
- [FILE PATH] .env file present — Gitignored: yes/no

### Summary
- Critical: N | High: N | Info: N
- .env files found: N (committed: N, gitignored: N)
- Immediate rotation required: [yes/no — list patterns if yes]

Tools: Read, Grep, Glob
```

Gate: Print the secret detection summary (Critical/High counts, rotation required). Ask:

```
Secret detection complete — Critical: N, High: N.  Rotation required: [yes/no]
Proceed to VULNERABILITY SCAN? [y/N]
```

Wait for user confirmation before continuing.

---

### Stage 2 — VULNERABILITY SCAN
Spawn the `backend-security` agent.

Agent prompt:
```
You are the backend-security agent performing a code vulnerability scan.

Target directory: {{TARGET}}
Language: {{LANGUAGE}}
Framework: {{FRAMEWORK}}
Database: {{DB}}
Auth mechanism: {{AUTH_MECHANISM}}

Read profiles/backend/rules/backend-security-guardrails.md before starting.
Every finding requires a FILE:LINE reference. No general observations without location.

---

### 2.1 Injection vulnerabilities

**SQL injection**
Search for string interpolation / concatenation used to build SQL queries:
- Node.js: `` `SELECT * FROM users WHERE id = ${userId}` `` — template literal in query
- Python: `f"SELECT * FROM ... WHERE id = {user_id}"` — f-string in query
- Go: `fmt.Sprintf("SELECT ... WHERE id = %s", id)` — Sprintf in query
- Java: `"SELECT ... WHERE id = " + id` — string concat in query
- Ruby: `"SELECT ... WHERE id = #{id}"` — interpolation in query

Flag any query construction that is not parameterized / uses ORM query builder.
Compliant patterns to accept (not flag): `?` placeholders, `$1` positional params,
named params (`:id`), ORM `where({ id: userId })`, SQLAlchemy `text(...).bindparams(...)`.

**Command injection**
Search for OS command execution with user-controlled input:
- Node.js: `exec(`, `execSync(`, `spawn(`, `execFile(` — check if any arg derives from request
- Python: `subprocess.run(`, `os.system(`, `os.popen(` — check for f-string or concat args
- Go: `exec.Command(` — check if command string includes user input
- PHP: `exec(`, `shell_exec(`, `system(`, `passthru(`, backtick operator

Compliant: fixed command string with validated, allowlisted arguments.

**Path traversal**
Search for file system operations that use user-supplied path segments:
- `fs.readFile(req.params.filename` or `req.query.path` — unsanitised path
- `path.join(baseDir, userInput)` without validation that the result stays within baseDir
- `open(user_input, 'r')` in Python without `os.path.abspath` + prefix check
- `os.ReadFile(filepath.Join(base, r.URL.Query().Get("file")))` in Go

Compliant: `path.join` result validated with `.startsWith(baseDir)` after `path.resolve`.

**NoSQL injection (if {{DB}} is mongodb)**
- `Model.find({ $where: userInput })` — arbitrary JS execution in MongoDB
- `Model.find({ field: { $regex: userInput } })` — ReDoS risk if input not sanitised
- User input used directly in a MongoDB filter object without field-level validation

### 2.2 Authentication and authorization flaws

**Missing auth middleware**
- Routes that handle sensitive data or mutations without an auth middleware applied
- Middleware applied at router level but individual routes that bypass it
- GraphQL resolvers without auth context check (if {{API_STYLE}} is graphql)

**JWT weaknesses**
- JWT library called with `algorithms: ['none']` or algorithm not explicitly specified
- `jwt.decode()` used instead of `jwt.verify()` (decode skips signature verification)
- JWT secret with fewer than 32 characters (brute-forceable)
- No expiry (`exp` claim) on issued tokens
- Refresh token rotation not implemented (refresh tokens usable multiple times)

**Password handling**
- `md5(password)` or `sha1(password)` or `sha256(password)` used for password hashing
  (must use bcrypt, argon2, scrypt, or PBKDF2 with high iteration count)
- `Math.random()` or `crypto.randomBytes` with small byte count (<16 bytes) used for
  security-sensitive token generation

**Missing authorization checks**
- Resource fetched by ID without verifying `resource.ownerId === currentUser.id`
  (IDOR — also flagged in OWASP API1 context)
- Admin flag checked only at login, not on each request
  (`user.role` read from JWT payload without database re-validation for sensitive operations)

### 2.3 Cryptographic weaknesses

- `MD5` or `SHA1` used for any security purpose (integrity, signatures, password hashing)
- ECB mode for symmetric encryption (`AES-ECB`, `Cipher.getInstance("AES")` in Java without mode)
- Hard-coded encryption key in source (also caught in Stage 1 — note if overlapping)
- Weak key derivation: `crypto.createHash('sha256').update(password).digest()` used as
  encryption key instead of PBKDF2/argon2
- `Math.random()` used to generate tokens, nonces, salts, or OTP codes
  (must use `crypto.randomBytes`, `secrets.token_bytes`, `crypto/rand`)
- Predictable token patterns (e.g. `userId + timestamp` as session token)

### 2.4 Error handling and information leakage

Search for:
- Stack traces returned in API error responses:
  `res.json({ error: err.stack })` or `res.json(err)` directly
- Internal paths exposed: error message containing filesystem paths
  (regex: `\/home\/`, `\/var\/`, `C:\\Users\\`, `\/app\/`)
- Database error objects returned directly to clients (ORM error with query details)
- `console.error(err)` in request handlers where `err` may contain user PII

Compliant: generic error message to client + full error logged server-side with correlation ID.

### 2.5 Dependency vulnerabilities
Read `package.json` (Node), `requirements.txt` / `pyproject.toml` (Python),
`go.mod` (Go), or `pom.xml` / `build.gradle` (Java).

Flag these known-vulnerable or high-risk patterns:
- `lodash` < 4.17.21 — prototype pollution (CVE-2021-23337)
- `node-fetch` < 2.6.7 — ReDoS (CVE-2022-0235)
- `axios` < 0.21.2 — SSRF (CVE-2020-28168)
- `jsonwebtoken` < 9.0.0 — algorithm confusion (CVE-2022-23529)
- `express` < 4.18.2 — open redirect (CVE-2022-24999)
- `django` < 4.2.x LTS — check for current LTS version
- `flask` < 2.3.0 — check CVE database
- `crypto` package for Node.js imported as `require('crypto')` — this is the built-in,
  not the deprecated npm package; only flag if `npm install crypto` is in package.json
- Any package with `0.x.x` version in production dependencies (unstable API, security support not guaranteed)

Recommend running: `npm audit` / `pip-audit` / `govulncheck` / `mvn dependency-check:check`
as part of CI.

### 2.6 Insecure direct object references and business logic
- Numeric sequential IDs used for resources accessible without ownership check
  (GET /api/invoices/12345 — can any authenticated user access any invoice by guessing the ID?)
- Pagination offset/limit manipulated to access other users' data in sorted queries
- Bulk operations (delete all, export all) without per-resource ownership verification

---

### Output format

## Vulnerability Scan Report — {{TARGET}}

### Critical (remotely exploitable — immediate action required)
- [FILE:LINE] **CWE-NNN: [Name]** — OWASP: [Category] — Description — Exact fix

### High (significant security risk — fix before next release)
- [FILE:LINE] **CWE-NNN: [Name]** — OWASP: [Category] — Description — Fix

### Medium (security hardening — fix in sprint)
- [FILE:LINE] **CWE-NNN: [Name]** — Description — Recommendation

### Low / Informational
- [FILE:LINE] Description — Note

### Dependency findings
- [PACKAGE@VERSION] — Known vulnerability — CVE if available — Upgrade to: VERSION

### Summary
- Critical: N | High: N | Medium: N | Low: N
- Dependency issues: N

Tools: Read, Grep, Glob
```

Gate: Print the vulnerability scan summary. Ask:

```
Vulnerability scan complete — Critical: N, High: N, Medium: N, Dependency issues: N.
Proceed to REMEDIATION REPORT? [y/N]
```

Wait for user confirmation before continuing.

---

### Stage 3 — REMEDIATION REPORT
Spawn the `backend-security` agent.

Agent prompt:
```
You are the backend-security agent producing the remediation report.

Target: {{TARGET}}
Language: {{LANGUAGE}}
Framework: {{FRAMEWORK}}
Ticket system: {{TICKET_SYSTEM}}
Secrets manager: {{SECRETS_MANAGER}}

Secret detection findings (Stage 1):
{{SECRET_OUTPUT}}

Vulnerability scan findings (Stage 2):
{{VULN_OUTPUT}}

Produce the full remediation report covering all Critical and High findings.

---

### 1. Prioritised finding inventory
For every Critical and High finding from Stages 1 and 2:

---
**[FINDING ID] — [Finding title]**
Stage: Secret Detection (S1) / Vulnerability Scan (S2)
Severity: Critical / High
CWE: CWE-NNN — [CWE name] (for S2 findings)
OWASP: [OWASP API Top 10 reference or OWASP Top 10 reference if applicable]
Location: FILE:LINE
Language: {{LANGUAGE}}

**Description:**
[2–3 sentences: what is the problem, how it can be exploited, what data is at risk]

**Before (vulnerable code):**
```[language]
// exact vulnerable code from the file (redact any secret values)
```

**After (remediated code):**
```[language]
// exact fix — complete, compilable, production-ready
// For secret findings: show the env-var pattern using {{SECRETS_MANAGER}}
```

**For secrets using {{SECRETS_MANAGER}}:**
- If aws-secrets: `const secret = await secretsManager.getSecretValue({ SecretId: 'prod/app/api-key' })`
- If gcp-secret-manager: `const [version] = await client.accessSecretVersion({ name: 'projects/.../secrets/.../versions/latest' })`
- If hashicorp-vault: `const { data } = await vault.read('secret/data/app/api-key')`
- If env-file: `const apiKey = process.env.API_KEY; if (!apiKey) throw new Error('API_KEY env var not set')`

**Verification:**
[How to confirm the fix is working — unit test assertion, curl command, log line to check]

---

### 2. Ticket creation instructions
For each Critical and High finding, provide exact ticket details for {{TICKET_SYSTEM}}:

**If {{TICKET_SYSTEM}} is jira:**
  Project: [from jira.config.md → jira_project_key]
  Issue type: Bug
  Summary: "Security Bug: [CWE short name] in [module/file name]"
  Priority: Blocker (Critical) / High (High)
  Labels: security, backend-security, [cwe-nnn]
  Description:
    h3. Security Finding
    Severity: [Critical/High]
    CWE: [CWE-NNN]
    OWASP: [reference]
    h3. Location
    [FILE:LINE]
    h3. Problem
    [description]
    h3. Fix
    [remediation approach — no actual secret values]
    h3. Acceptance criteria
    - [ ] Vulnerable code removed or patched
    - [ ] Unit test added to prevent regression
    - [ ] Secret rotated (if S1 finding)
    - [ ] Security team notified (Critical only)
    - [ ] Change deployed to production and verified

**If {{TICKET_SYSTEM}} is linear:**
  Title: "Security: [CWE short name] — [module name]"
  Priority: Urgent (Critical) / High (High)
  Labels: security, bug
  Description: [same structure in markdown]

**If {{TICKET_SYSTEM}} is github-issues:**
  Title: "[SECURITY] [CWE-NNN]: [one-line description]"
  Labels: security, bug, priority:critical or priority:high
  Body: [markdown with Security Finding / Location / Problem / Fix / Acceptance criteria]

### 3. Immediate action items (Critical findings only)
List in execution order:
1. Rotate any exposed credentials (within 24 hours of discovery)
2. Deploy patched code to production
3. Audit access logs for exploitation of the vulnerability (date range: last 90 days)
4. Notify affected users if PII was potentially exposed (check applicable regulations)

### 4. Regression prevention
For each vulnerability category found, recommend a prevention control:
- SQL injection found → add SQLMap or similar to CI pipeline
- Secrets found → add detect-secrets or gitleaks pre-commit hook + CI check
- Dependency vulnerabilities → add `npm audit --audit-level=high` to CI as a required check
- JWT weaknesses → add auth unit tests that assert algorithm rejection

Tools: Read
```

After all three stages complete, print the final summary report:

```
════════════════════════════════════════════════════════
  Backend Security Scan — {{TARGET}}
════════════════════════════════════════════════════════
  [✓] Stage 1 — SECRET DETECTION    Critical: N, High: N
                                     Rotation required: [yes/no]
  [✓] Stage 2 — VULNERABILITY SCAN  Critical: N, High: N, Medium: N
                                     Dependency issues: N
  [✓] Stage 3 — REMEDIATION         Report complete, N tickets specified
════════════════════════════════════════════════════════

IMMEDIATE ACTION REQUIRED (Critical):
  [List each Critical finding as: FINDING-ID — FILE:LINE — one-line description]

Tickets to create in {{TICKET_SYSTEM}}:
  Blocker / Critical:
    - [FINDING-ID] [summary]
  High:
    - [FINDING-ID] [summary]

Regression controls to add to CI:
  [list recommended CI additions based on finding categories]
```

---

## Variables

- `{{TARGET}}` = argument passed to this command (directory path or `full`)
- `{{LANGUAGE}}` = from `backend.config.md` → `language`
- `{{FRAMEWORK}}` = from `backend.config.md` → `framework`
- `{{DB}}` = from `backend.config.md` → `database_primary`
- `{{CLOUD}}` = from `backend.config.md` → `cloud`
- `{{SECRETS_MANAGER}}` = from `backend.config.md` → `secrets_manager`
- `{{AUTH_MECHANISM}}` = from `backend.config.md` → `auth_strategy`
- `{{API_STYLE}}` = from `backend.config.md` → `api_style`
- `{{TICKET_SYSTEM}}` = from `workflow.config.md` → `ticket_system`
- `{{SECRET_OUTPUT}}` = Stage 1 output (first 3000 chars)
- `{{VULN_OUTPUT}}` = Stage 2 output (first 3000 chars)
