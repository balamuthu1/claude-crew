# Testing Standards

These rules apply to all QA and testing work.

## Test pyramid

```
        /\
       /E2E\        ~10% — critical user journeys only
      /------\
     /Integr. \     ~20% — service/API/DB boundaries
    /----------\
   /Unit tests  \   ~70% — business logic, isolated
  /--------------\
```

Invert the pyramid = slow, brittle test suite. Keep the ratio.

## Test naming

Format: `should <result> when <condition>`

Good:
- `should return 404 when user does not exist`
- `should deduct stock when order is confirmed`
- `should throw ValidationError when email is malformed`

Bad:
- `test1`, `test user`, `userServiceTest`

## Test structure (AAA)

```
Arrange  →  set up test data and mocks
Act      →  call the function/endpoint being tested
Assert   →  verify the outcome
```

Each test covers one behaviour. One assertion per test is ideal (multiple is acceptable when they all verify the same outcome).

## Unit test standards

- Mock all I/O: database, network, filesystem, time
- Tests must run without external dependencies
- No global state shared between tests
- Test the public interface, not implementation details
- Cover: happy path, validation failure, not-found, edge cases

## Integration test standards

- Use a real database with transactions (roll back after each test)
- Use test containers (Docker) for external dependencies
- Tests must be independent and runnable in any order
- Seed data via factories/fixtures — no hardcoded magic values

## E2E test standards

- Test critical user journeys: signup, login, checkout, key feature flows
- `data-testid` attributes for selectors (never CSS classes or positions)
- No `sleep()` — explicit waits for conditions
- Each test cleans up after itself
- Parallel execution supported (no shared state between tests)

## Coverage targets

| Layer | Target |
|-------|--------|
| Service / domain logic | ≥ 80% |
| Auth critical paths | 100% |
| API endpoints (integration) | All happy paths + key error codes |
| E2E | All critical user journeys |

## Test data management

- Factories/builders for test objects — not manual object construction per test
- No production data in tests
- No hardcoded magic values — use named constants
- PII in test data must be obviously fake: `test-user@example.com`, `John Testname`

## Flaky test policy

Flaky tests must be fixed, not retried. To triage a flaky test:
1. Check for shared state between tests
2. Check for timing dependencies (`sleep`, animation)
3. Check for environment-specific behaviour
4. Check for data ordering assumptions

A test that passes 90% of the time is a bug — find the 10%.
