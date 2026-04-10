# QA Security Guardrails

These rules apply to all QA tooling and test automation.

## Non-bypassable rules

1. **Never commit test credentials** — Cypress env files, `.env.test`, `.env.staging` with real credentials must never be committed.
2. **Never use production data in tests** — test against a separate environment with synthetic data only.
3. **Never hardcode staging/production URLs with auth tokens** — use environment variable injection in CI.
4. **Never log test outputs containing PII** — screenshots, network recordings, and test reports must be scrubbed of PII before sharing.

## Sensitive file patterns (block commit)

```
cypress.env.json
.env.test
.env.staging
.env.e2e
playwright.env
jmeter.properties      # may contain credentials
*.jmx                  # JMeter test plans may contain passwords
```

## Test environment isolation

- Tests must run against dedicated test environments — never directly against production
- Test accounts must be dedicated test accounts — never real user accounts
- Test data must be deterministically generated — use factories with predictable seeds
- Test environments must have realistic but anonymised data (not copies of production PII)

## CI/CD security for test pipelines

- Store test environment credentials in CI secret store, not in files
- Test reports uploaded to internal storage — not public S3 buckets
- Screenshots/videos from tests may contain sensitive UI — restrict access
- Dependency audit (npm audit, pip-audit) must run in test pipeline

## Vulnerability testing scope

QA engineers may perform:
- Functional negative testing (invalid inputs, boundary conditions)
- Basic auth testing (unauthenticated access, wrong user access)
- Load testing within agreed limits

QA engineers must NOT perform without explicit security team sign-off:
- Active exploitation of vulnerabilities
- Fuzzing in production
- Social engineering tests
- Network scanning beyond the test environment
