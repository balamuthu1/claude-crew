---
description: 4-stage regression suite management command. Argument is "full", "smoke", or a feature area name. Audits the suite, fills coverage gaps, cleans up stale tests, and optimises for speed.
argument: scope — "full" (entire suite), "smoke" (smoke suite only), or a feature area name (e.g. "checkout", "auth", "search")
---

Run a full regression suite management workflow for the scope described in the argument.

You are the **orchestrator**. Do NOT audit, write, or edit tests yourself — spawn
a dedicated sub-agent for each stage using the `Agent` tool. Each sub-agent gets
an isolated context window focused on its domain.

---

## Before starting

Read `qa.config.md` and `workflow.config.md`. Extract the following variables and
inject them into every agent prompt below:

- `{{SCOPE}}` — argument passed to this command ("full", "smoke", or feature area)
- `{{E2E_FRAMEWORK}}` — e.g. Playwright, Cypress, Appium, Espresso (from qa.config.md)
- `{{UNIT_FRAMEWORK}}` — e.g. JUnit 5, pytest, Vitest, Jest, XCTest (from qa.config.md)
- `{{INTEGRATION_FRAMEWORK}}` — e.g. REST Assured, Supertest, Spring Test (from qa.config.md)
- `{{TICKET_SYSTEM}}` — e.g. Jira, Linear, GitHub Issues (from workflow.config.md)
- `{{TEST_DIR}}` — root path of the test directory (from qa.config.md, default: `tests/`)
- `{{CI_CONFIG}}` — path to CI configuration file (from qa.config.md, e.g. `.github/workflows/ci.yml`)
- `{{COVERAGE_THRESHOLD}}` — minimum coverage % for the suite to pass (from qa.config.md, default: 80%)

If any config file is missing, note the missing values and proceed using the
defaults shown above in parentheses.

---

## Stage Definitions

### Stage 1 — SUITE AUDIT
Spawn the `test-strategist` agent.

Agent prompt:
```
You are the test-strategist agent conducting a regression suite audit.

Scope: {{SCOPE}}
Test directory: {{TEST_DIR}}
E2E framework: {{E2E_FRAMEWORK}}
Unit framework: {{UNIT_FRAMEWORK}}
Coverage threshold: {{COVERAGE_THRESHOLD}}

Read qa.config.md and workflow.config.md.
Read profiles/qa/rules/testing-standards.md.

Perform a complete audit of the existing test suite. Work through each section
below systematically. Use Glob and Grep to scan the actual test files.

---

**Section 1 — Test Inventory**

Scan all test files under {{TEST_DIR}} and any co-located test files in the source
tree (files matching `*.test.*`, `*.spec.*`, `*_test.*`, `*Test.*`).

For each test file found, classify the test type:
- Unit: no I/O, no network, no database, pure logic
- Integration: real database or real HTTP calls
- E2E: browser or device automation

Produce an inventory table:

| File Path | Test Type | Test Count | Framework | Notes |
|-----------|-----------|-----------|-----------|-------|

Summary:
- Total test files: N
- Total test cases: N
- Unit: N  Integration: N  E2E: N

---

**Section 2 — Feature Coverage Map**

Identify what features / areas the project has by scanning:
- Directory structure under `src/`, `app/`, `lib/`
- Route definitions (Express routes, Next.js app dir, Django urls.py, etc.)
- Public API surface (controllers, resolvers, command handlers)

For each feature area found, determine if tests exist:

| Feature Area | Has Unit Tests | Has Integration Tests | Has E2E Tests | Coverage % (if known) |
|-------------|---------------|----------------------|---------------|----------------------|

Classify each area as:
- Well covered: all three levels present
- Partially covered: 1-2 levels present
- Not covered: zero tests for this area

---

**Section 3 — Flaky Test Detection**

Search for indicators of potentially flaky tests:
- `skip`, `xit`, `xtest`, `@Ignore`, `@Disabled` annotations (skipped tests)
- `retry`, `retryAttempts`, `--retries` configuration (retry logic = hidden flakiness)
- `sleep(`, `Thread.sleep(`, `time.sleep(` (timing-dependent tests)
- `setTimeout`, `setInterval` in test files without proper cleanup
- Tests that reference shared mutable state across test cases

List each flaky indicator found:
| File:Line | Pattern Found | Risk Level | Recommendation |
|-----------|--------------|------------|----------------|

---

**Section 4 — Slow Test Identification**

Identify tests likely to be slow:
- E2E tests that hit multiple pages or require full browser rendering
- Integration tests that seed large datasets
- Tests with long timeouts configured (e.g. `timeout: 60000`)
- Tests that test file I/O or external API calls without mocking

Estimate test suite total runtime based on typical benchmark times:
- Unit test: ~5ms average
- Integration test: ~100ms average
- E2E test: ~5s average

Estimated suite runtime: N minutes

---

**Section 5 — Outdated Test Detection**

Detect tests that are testing things that no longer exist:
- Import paths that reference files that don't exist
- Selectors (CSS classes, element IDs, data-testid values) that don't appear in
  the source code
- Tests for route paths that no longer exist in the router
- Tests for API endpoints that no longer exist
- References to deprecated methods or removed features

List outdated tests found:
| File:Line | Issue | Evidence |
|-----------|-------|---------|

---

**Section 6 — Coverage Gaps Summary**

Based on the Feature Coverage Map in Section 2, list gaps in priority order:
1. Feature areas with ZERO tests (highest priority — any defect goes undetected)
2. Critical paths (auth, payments, data writes) with only unit tests but no E2E
3. Feature areas recently changed (check git log) but without test updates
4. Error paths and edge cases missing from otherwise-covered areas

Output a prioritised gaps list:

## Coverage Gaps — Priority Order

### P0 — Zero Coverage (must fix)
| Feature Area | Risk Level | Suggested Test Types |
|-------------|-----------|---------------------|

### P1 — Critical Paths Incomplete
| Feature Area | Missing Test Type | Why Critical |
|-------------|------------------|-------------|

### P2 — Recently Changed, Untested
| Feature Area | Last Changed (approx) | Missing Tests |
|-------------|----------------------|--------------|

### P3 — Edge Cases and Error Paths
| Feature Area | Missing Scenarios |
|-------------|-----------------|

---

**Section 7 — Suite Health Score**

Calculate a health score (0–100):
- Start at 100
- Deduct 10 per P0 gap (zero coverage area)
- Deduct 5 per P1 gap
- Deduct 3 per P2 gap
- Deduct 2 per flaky test indicator found
- Deduct 1 per outdated test found

**Suite Health Score: N/100**
Interpretation: 90–100 = Excellent | 75–89 = Good | 60–74 = Needs work | <60 = Critical

Tools: Read, Grep, Glob
```

Gate: Print audit summary (inventory totals, health score, gap count by priority). Ask "Audit complete. Proceed to FILL COVERAGE GAPS? [y/N]"

---

### Stage 2 — FILL COVERAGE GAPS
Spawn the `automation-engineer` agent.

Agent prompt:
```
You are the automation-engineer filling coverage gaps identified in the suite audit.

Scope: {{SCOPE}}
E2E framework: {{E2E_FRAMEWORK}}
Unit framework: {{UNIT_FRAMEWORK}}
Test directory: {{TEST_DIR}}

Audit results from Stage 1 (first 2500 chars):
{{AUDIT_OUTPUT}}

Read qa.config.md.
Read profiles/qa/rules/testing-standards.md.

Work through the P0 gaps first, then P1 gaps from the Stage 1 audit.
For {{SCOPE}}: if "full", address all gap priorities; if "smoke", address P0 and
P1 critical path gaps only; if a feature area name, address only gaps for that area.

**Test writing requirements — apply to every test written:**

Test naming:
- Format: `should [expected behaviour] when [condition]`
- Be specific — "should return 404 when user ID does not exist" not "tests 404"
- Name the test after the behaviour, not the function

Test structure (AAA):
- Arrange: set up all preconditions and test data
- Act: perform the single action being tested
- Assert: verify the outcome — use the most specific assertion available

Independence:
- Every test must be independently runnable (no sequential dependencies)
- Use beforeEach/afterEach to set up and tear down state
- Never share mutable state between test cases
- Create test data in the test, don't rely on pre-existing data

E2E tests ({{E2E_FRAMEWORK}}):
- Follow Page Object Model — selectors live in page object classes, never in tests
- Use data-testid attributes exclusively for element selection
- No sleep() — explicit waits for conditions (element visible, network idle, text present)
- Each E2E test covers one complete user journey (start → action → verified outcome)
- Capture screenshot on failure (configure in framework setup if not already done)
- Login once per suite (beforeAll hook), not in every test

Unit tests ({{UNIT_FRAMEWORK}}):
- Mock all I/O: database, network, filesystem, time, random
- Test the public interface, not implementation details
- Cover: happy path, validation failure, not-found case, permission denied
- Test edge cases explicitly: null inputs, empty collections, boundary values

Coverage priority per test type:
- Any flow involving money, auth, or data writes → requires E2E + unit coverage
- API endpoints → requires integration test for each status code (200, 400, 401, 403, 404, 500)
- Business logic with branches → unit tests for each branch
- UI components with states → unit tests for loading, error, empty, populated states

For each gap being filled, write the tests as complete, production-ready files.
No TODOs. No pseudocode. No placeholder assertions.

After writing all tests, output a list of files created:

## New Tests Written

| File Path | Test Type | Tests Added | Coverage Area |
|-----------|-----------|------------|---------------|

Total new tests: N

Tools: Read, Write, Edit, Glob
```

Gate: Print the list of new test files and test count. Ask "New tests look good? Proceed to MAINTENANCE PASS? [y/N]"

---

### Stage 3 — MAINTENANCE PASS
Spawn the `automation-engineer` agent.

Agent prompt:
```
You are the automation-engineer performing a maintenance pass on the existing
regression suite to fix quality issues identified in the audit.

Scope: {{SCOPE}}
E2E framework: {{E2E_FRAMEWORK}}
Unit framework: {{UNIT_FRAMEWORK}}
Test directory: {{TEST_DIR}}

Audit results from Stage 1 (first 2500 chars):
{{AUDIT_OUTPUT}}

Read qa.config.md.
Read profiles/qa/rules/testing-standards.md.

Work through each issue type below. For {{SCOPE}}: if "smoke", only fix flaky
tests and broken selectors; if "full", address all issue types.

**Issue Type 1 — Delete tests for removed features**
From the Stage 1 "outdated tests" list, delete tests that:
- Reference source files, functions, or classes that no longer exist
- Test route paths or API endpoints that no longer exist
- Import from paths that do not resolve
Before deleting, verify the feature is actually gone (check source tree).
Log each deletion: "Deleted [file] — tests [X] removed features: [reason]"

**Issue Type 2 — Fix broken selectors**
For E2E tests using CSS classes, element positions, or text content as selectors:
- Replace with data-testid selectors
- If data-testid attributes don't exist on the elements yet, add them to the
  source component files AND update the test
- CSS class selectors like `.btn-primary` → `[data-testid="submit-button"]`
- Position selectors like `:nth-child(3)` → `[data-testid="product-card-3"]`
- Text selectors like `text("Continue")` → `[data-testid="checkout-continue-btn"]`

**Issue Type 3 — Replace hardcoded waits**
Find all occurrences of:
- `sleep(N)`, `Thread.sleep(N)`, `time.sleep(N)`, `await new Promise(r => setTimeout(r, N))`
- `waitForTimeout(N)` with a fixed N (Playwright)
- `cy.wait(N)` with a number argument (Cypress)

Replace each with an explicit condition wait:
- "Wait for element X to be visible" — use framework's `waitForSelector` / `should('be.visible')`
- "Wait for network request to complete" — use framework's `waitForResponse` / intercept
- "Wait for text to appear" — use `waitForText` / `contain.text`
- "Wait for URL change" — use `waitForURL` / `cy.url().should('include', ...)`

Document each change: "Replaced sleep(3000) at [file:line] with waitForSelector('[data-testid=result]')"

**Issue Type 4 — Break test dependencies**
Find tests that depend on execution order:
- Tests that require another test to run first to create data
- Tests that assume a specific order via `describe.only` or ordering by filename
- afterAll hooks that clean up data other tests depend on

Refactor to make each test create its own precondition data in beforeEach.
This may require creating factory/builder functions if they don't already exist.

**Issue Type 5 — Fix implementation-detail tests**
Find unit tests that:
- Assert on private methods or internal state
- Assert on the exact number of times a mock was called (unless that IS the behaviour)
- Break when you refactor without changing external behaviour
- Use `spy.calls.length` or `mock.calls[0][2]` style fragile assertions

Refactor to test observable behaviour:
- Input → output assertions instead of internal state assertions
- "Should return X when given Y" not "Should call internalMethod once"
- Test through the public API

**Issue Type 6 — Consolidate duplicate coverage**
Find tests that cover identical scenarios with no additional value:
- Multiple tests that all test "user can log in" with the same inputs
- E2E tests that duplicate what integration tests already verify thoroughly
- Unit tests that are strict subsets of other unit tests in the same file

Consolidate by:
- Keeping the lower-level test (prefer unit over E2E for identical scenario)
- Removing pure duplicates
- Merging tests that can be parameterised into a single data-driven test

After all fixes, output a summary:

## Maintenance Pass Results

### Deleted Tests
| File | Tests Removed | Reason |
|------|--------------|--------|

### Selector Fixes
| File:Line | Old Selector | New Selector |
|-----------|-------------|-------------|

### Wait Replacements
| File:Line | Removed | Replaced With |
|-----------|---------|--------------|

### Dependency Fixes
| File | Issue | Fix Applied |
|------|-------|------------|

### Tests consolidated / removed as duplicate
| File | Count removed | Kept in |
|------|--------------|---------|

Total files modified: N  |  Tests removed: N  |  Tests fixed: N

Tools: Read, Edit, Glob, Grep
```

Gate: Print maintenance summary. Ask "Maintenance pass looks good? Proceed to SUITE OPTIMISATION? [y/N]"

---

### Stage 4 — OPTIMISE SUITE SPEED
Spawn the `automation-engineer` agent.

Agent prompt:
```
You are the automation-engineer optimising the regression suite for speed and
CI efficiency.

Scope: {{SCOPE}}
E2E framework: {{E2E_FRAMEWORK}}
Unit framework: {{UNIT_FRAMEWORK}}
CI config: {{CI_CONFIG}}
Test directory: {{TEST_DIR}}

Audit results from Stage 1 (first 2000 chars):
{{AUDIT_OUTPUT}}

Read qa.config.md and {{CI_CONFIG}} (if it exists).

---

**Task 1 — Configure Parallel Execution**

For {{E2E_FRAMEWORK}}, configure maximum parallel test execution:

Playwright: update `playwright.config.ts` / `playwright.config.js`:
  - Set `workers` to the number of CPU cores available (or `process.env.CI ? 2 : undefined`)
  - Set `fullyParallel: true` to enable parallel execution within a spec file
  - Set `forbidOnly: !!process.env.CI` to prevent accidental .only in CI
  - Set `retries: process.env.CI ? 1 : 0` (one retry in CI only — not to mask flakiness)

Cypress: update `cypress.config.js`:
  - Enable `experimentalRunAllSpecs: true` for faster sequential runs
  - Document that Cypress Cloud is required for true parallelism (add comment)
  - Configure `testIsolation: true` to enforce independent tests

Jest / Vitest: update config file:
  - Set `maxWorkers: '50%'` for unit tests (leave CPU headroom)
  - Enable `--runInBand` only for integration tests that share a database

JUnit (Java): update build tool config:
  - Configure Surefire / Failsafe with `forkCount` and `reuseForks`
  - Set parallel execution mode: `methods` for unit, `none` for integration

pytest: update `pytest.ini` or `pyproject.toml`:
  - Add `pytest-xdist` configuration: `-n auto` for unit, `-n 2` for integration

Write the updated config file(s). Comment every change with the reason.

---

**Task 2 — Global Setup / Teardown**

Identify setup that runs per-test but could safely run once per suite:
- Database schema creation or migration → run once in global setup
- Test user account creation (read-only accounts) → run once in global setup
- Loading test fixtures that are read-only → run once in global setup
- Auth token generation for read-only sessions → run once, share across tests

Move these to:
- Playwright: `globalSetup` / `globalTeardown` in playwright.config
- Cypress: `cypress/support/e2e.js` global hooks or `before()` in support file
- Jest/Vitest: `globalSetup` / `globalTeardown` in config
- pytest: session-scoped fixtures

Important: only move to global setup if the data is IMMUTABLE during tests.
Any data a test writes must still be set up per-test with cleanup.

Write the global setup/teardown file.

---

**Task 3 — Test Data Strategy**

Evaluate and recommend the test data approach for this project:

Option A — Factory functions (recommended for most projects):
- Factory creates a new object with sensible defaults, accepts overrides
- Example: `userFactory({ role: 'admin' })` creates an admin user
- Created in the test, cleaned up in afterEach
- Best for: integration and unit tests

Option B — Fixtures (static JSON/YAML files):
- Fixed data loaded from files
- Best for: read-only reference data (product catalogue, config data)
- Avoid for: user accounts, orders, anything that can be mutated

Option C — Database seeding (run before suite):
- One-time seed of reference data that all tests read
- Must be idempotent (safe to re-run)
- Best for: lookup tables, enum values, static config

Recommend the right option for this project based on the stack detected in
qa.config.md. Write a factory module (Option A) for the 3 most commonly needed
test objects in this project (infer from test files which objects are created
most often).

---

**Task 4 — Define Smoke Suite**

A smoke suite runs in under 5 minutes and covers the highest-risk paths.

Identify the N tests that together satisfy:
- All auth flows (login, logout, token refresh)
- All "money paths" (checkout, payment, subscription)
- All critical data mutations (create, update, delete for core entities)
- The primary user journey from landing to completing the key value action

Recommend N tests for the smoke suite (N should target < 5 min runtime).
Mark these tests with a smoke tag/label:
- Playwright: use `tag: ['@smoke']` in test options
- Cypress: use `tags: ['smoke']` in test options
- Jest/pytest: use a custom marker or naming convention (`smoke.test.ts`)

Write a smoke suite configuration file that runs only tagged tests.

---

**Task 5 — CI Integration Snippet**

Write an updated CI job snippet for {{CI_CONFIG}} that:
- Runs the smoke suite on every PR (fast feedback, < 5 min)
- Runs the full regression suite nightly or post-merge to main
- Fails the PR if smoke suite fails
- Reports test results as CI artifacts (JUnit XML)
- Shows flaky test summary in PR comments (if CI platform supports it)

Format the snippet appropriately for the CI system (GitHub Actions YAML,
GitLab CI YAML, Jenkinsfile, CircleCI config, etc.) detected from {{CI_CONFIG}}.

Write the snippet as a new job or updated job in the CI config.

---

Output a summary of all changes:

## Suite Optimisation Results

### Parallel Execution
- Config updated: [file]
- Worker count: [N]
- Estimated speedup: Nx

### Global Setup
- File written: [path]
- Operations moved to global setup: [list]

### Test Data
- Recommendation: [Factory / Fixture / Seed]
- Factory file written: [path]
- Objects covered: [list]

### Smoke Suite
- Tests selected: N
- Estimated runtime: ~Xmin
- Tag used: [@smoke / smoke / other]

### CI Config
- File updated: [path]
- Smoke runs on: [trigger]
- Full regression runs on: [trigger]

Tools: Read, Write, Edit, Glob
```

---

## Regression Suite Summary Report

After all stages complete, print:

```
════════════════════════════════════════════════════════
  Regression Suite — {{SCOPE}}
════════════════════════════════════════════════════════
  [✓] Stage 1 — AUDIT
      Total tests: N  |  Unit: N  |  Integration: N  |  E2E: N
      Health score: N/100
      P0 gaps: N  |  P1 gaps: N  |  Flaky indicators: N  |  Outdated: N

  [✓] Stage 2 — FILL COVERAGE GAPS
      New test files: N
      New test cases: N
      P0 gaps closed: N

  [✓] Stage 3 — MAINTENANCE PASS
      Tests deleted: N  |  Selectors fixed: N
      Hardcoded waits replaced: N  |  Dependencies broken: N

  [✓] Stage 4 — OPTIMISATION
      Parallel config: written  |  Workers: N
      Global setup: written
      Test data: [strategy]
      Smoke suite: N tests, ~Xmin runtime
      CI config: updated
════════════════════════════════════════════════════════

Coverage now: [list feature areas now covered]
Still missing: [areas not yet covered — future work, with reason]
Smoke suite: [N tests, ~Xmin — tags used: @tag]

Run commands:
  Smoke suite:       [framework-specific run command with smoke filter]
  Full regression:   [framework-specific full run command]
  With coverage:     [framework-specific coverage run command]
```

---

## Variables

- `{{SCOPE}}` = argument passed to this command ("full", "smoke", or feature area name)
- `{{E2E_FRAMEWORK}}` = from qa.config.md (e.g. Playwright, Cypress, Appium)
- `{{UNIT_FRAMEWORK}}` = from qa.config.md (e.g. JUnit 5, pytest, Vitest, Jest)
- `{{INTEGRATION_FRAMEWORK}}` = from qa.config.md (e.g. REST Assured, Supertest)
- `{{TICKET_SYSTEM}}` = from workflow.config.md (e.g. Jira, Linear, GitHub Issues)
- `{{TEST_DIR}}` = from qa.config.md (default: `tests/` or `__tests__/`)
- `{{CI_CONFIG}}` = from qa.config.md (e.g. `.github/workflows/ci.yml`)
- `{{COVERAGE_THRESHOLD}}` = from qa.config.md (default: 80%)
- `{{AUDIT_OUTPUT}}` = Stage 1 audit output (first 2500 chars)
