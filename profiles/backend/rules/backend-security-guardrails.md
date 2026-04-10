# Backend Security Guardrails

These rules apply to all backend development. They extend the shared security guardrails.

## Non-bypassable rules

1. **Never write SQL by string concatenation** — always use parameterised queries or ORM.
2. **Never log sensitive fields** — passwords, tokens, card numbers, SSNs, API keys must never appear in logs.
3. **Never commit credentials** — connection strings, API keys, passwords must use environment variables or a secrets manager.
4. **Never expose internal error details** — stack traces, internal service names, and database errors must not reach API consumers.
5. **Never trust client-provided IDs for authorisation** — always verify the authenticated user owns the resource.

## OWASP API Security Top 10 — quick reference

| # | Vulnerability | Prevention |
|---|---------------|------------|
| 1 | Broken Object Level Authorisation | Verify ownership on every request |
| 2 | Broken Authentication | Short-lived JWTs, rotate refresh tokens, secure cookie flags |
| 3 | Broken Object Property Level Authorisation | Allowlist fields in responses; block mass assignment |
| 4 | Unrestricted Resource Consumption | Rate limiting, pagination limits, max file size |
| 5 | Broken Function Level Authorisation | Role checks on every endpoint; no security by obscurity |
| 6 | Unrestricted Sensitive Business Flows | Bot detection, step validation, idempotency keys |
| 7 | SSRF | Allowlist outbound URLs; never fetch user-controlled URLs without validation |
| 8 | Security Misconfiguration | CORS restricted, debug mode off in production, no default credentials |
| 9 | Improper Inventory Management | API gateway with full inventory; deprecate old versions |
| 10 | Unsafe Consumption of APIs | Validate third-party API responses; don't trust their schemas blindly |

## Sensitive file patterns (block read/write/commit)

```
kubeconfig
.kube/config
service-account.json
credentials.json
.pgpass
database.yml          # contains passwords
*.pem
*.key
.env*
```

## Authentication implementation

- JWT: always verify signature and expiry; use HS256 minimum, RS256 preferred
- Refresh tokens: rotate on every use; invalidate on logout
- Password hashing: bcrypt (cost 12+) or argon2id — never MD5/SHA1/unsalted
- Multi-factor auth: TOTP or WebAuthn — never SMS-only for high-risk actions
- Session fixation: regenerate session ID after login

## Injection prevention

| Type | Prevention |
|------|-----------|
| SQL injection | Parameterised queries / ORM |
| Command injection | Never pass user input to shell commands; use execFile not exec |
| Path traversal | Resolve paths against allowlisted root; reject `..` |
| SSRF | URL allowlist; internal network ranges blocked |
| XXE | Disable external entity processing in XML parsers |

## Infrastructure security

- Service accounts: least-privilege IAM roles
- Secrets: Vault, AWS Secrets Manager, GCP Secret Manager — never in env files committed to git
- Network: default-deny firewall rules; explicit allow only
- Container: non-root user; read-only filesystem where possible; no privileged containers
