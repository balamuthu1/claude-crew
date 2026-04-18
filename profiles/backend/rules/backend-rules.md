---
paths:
  - "**/*.py"
  - "**/*.go"
  - "**/*.java"
  - "**/*.sql"
  - "**/*.rb"
  - "**/*.rs"
  - "**/*.cs"
  - "**/Dockerfile"
  - "**/docker-compose*.yml"
  - "**/*.tf"
  - "**/migrations/**"
---

# Backend Rules

- NEVER write SQL by string concatenation — parameterised queries or ORM only.
- NEVER log sensitive fields: passwords, tokens, card numbers, SSNs, API keys.
- NEVER expose stack traces, internal service names, or DB errors to API consumers.
- NEVER trust client-provided IDs for authorisation — verify the authenticated user owns the resource.
- NEVER delete or modify existing database migration files.
- Use resource-based URLs with HTTP verbs; version APIs at `/v1/`.
- JWT: verify signature and expiry; RS256 preferred; rotate refresh tokens on every use.
- Passwords: bcrypt (cost 12+) or argon2id — never MD5, SHA1, or unsalted hashes.
- Rate-limit all public endpoints; enforce pagination limits and max file sizes.
- Secrets in Vault/AWS Secrets Manager/GCP Secret Manager — never committed to git.

## OWASP API Top 10 Quick Check

| # | Risk | Prevention |
|---|------|-----------|
| 1 | Broken Object Level Authz | Verify ownership on every request |
| 2 | Broken Authentication | Short-lived JWTs, rotate refresh tokens, secure cookie flags |
| 3 | Mass Assignment | Allowlist fields in responses; block mass assignment |
| 4 | Resource Consumption | Rate limiting, pagination limits, max file size |
| 5 | Function Level Authz | Role checks on every endpoint |
| 7 | SSRF | Allowlist outbound URLs; never fetch user-controlled URLs |
| 8 | Misconfiguration | CORS restricted; debug off in prod; no default credentials |
