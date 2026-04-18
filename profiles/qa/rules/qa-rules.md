---
paths:
  - "**/*Test*"
  - "**/*Spec*"
  - "**/*_test*"
  - "**/*_spec*"
  - "**/test/**"
  - "**/tests/**"
  - "**/spec/**"
  - "**/cypress/**"
  - "**/playwright/**"
  - "**/jest.config*"
  - "**/pytest.ini"
---

# QA Rules

- NEVER commit test credentials (`cypress.env.json`, `.env.test`, `.env.e2e`, etc.).
- NEVER use production data in tests — synthetic data in dedicated test environments only.
- Test naming: `should <result> when <condition>`.
- Test structure: Arrange / Act / Assert; one behaviour per test.
- No `sleep()` in tests — use explicit condition waits.
- Use `data-testid` selectors; never CSS classes, positions, or text content.
- Keep the test pyramid: ~70% unit, ~20% integration, ~10% E2E.
- Flaky tests must be fixed, not retried, skipped, or marked as known flaky.
- Mock all I/O in unit tests: database, network, filesystem, time.
- Use test containers (Docker) for external dependencies in integration tests.
- PII in test data must be obviously fake: `test-user@example.com`, `John Testname`.

## Coverage targets

| Layer | Target |
|---|---|
| Service / domain logic | ≥ 80% |
| Auth critical paths | 100% |
| API endpoints (integration) | All happy paths + key error codes |
| E2E | All critical user journeys |
