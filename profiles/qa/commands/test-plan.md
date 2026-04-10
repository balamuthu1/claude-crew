Run a full QA planning workflow for the feature or release described in the argument.

You are the **orchestrator**. Do NOT write test plans or test cases yourself — spawn
dedicated sub-agents for each stage. Each gets an isolated context window.

**For stages 3 and 4 (automation + performance): call `Agent` twice in a single message to run them in parallel.**

---

## Before starting

Read `qa.config.md` and `workflow.config.md`. Extract:
- `{{TEST_MGMT}}` — test management tool (jira, testrail, notion, spreadsheet, etc.)
- `{{E2E_FRAMEWORK}}` — e2e test framework
- `{{PERF_FRAMEWORK}}` — performance test framework
- `{{TICKET_SYSTEM}}` — ticket system from workflow.config.md
- `{{DOCS_PLATFORM}}` — docs platform from workflow.config.md

---

## Stage Definitions

### Stage 1 — RISK ANALYSIS
Spawn the `test-strategist` agent.

Agent prompt:
```
You are the test-strategist agent.

Feature/Release: {{FEATURE}}

Read qa.config.md and workflow.config.md.

Perform a risk-based analysis:

1. **Risk assessment matrix** — for each area of the feature, rate:
   - Likelihood of failure (High/Medium/Low)
   - Impact if it fails (Critical/High/Medium/Low)
   - Risk level = Likelihood × Impact

   Areas to always evaluate:
   - Authentication / authorisation logic
   - Data persistence (create, update, delete)
   - Payment or financial flows (if applicable)
   - Third-party integrations
   - Error handling and recovery
   - Performance under expected load
   - Accessibility

2. **Coverage recommendation**
   Based on risk, specify for each area:
   - Test type required (unit / integration / E2E / manual)
   - Priority (P0-must test / P1-should test / P2-nice to have)

3. **Test scope decision**
   - What is IN scope
   - What is OUT of scope and why
   - Regression risk: which existing features could break?

Output a risk matrix table and coverage recommendation.
```
Tools: Read, Grep, Glob

Gate: Print risk matrix. Ask "Risk analysis looks correct? Proceed to TEST DESIGN? [y/N]"

---

### Stage 2 — TEST DESIGN
Spawn the `test-strategist` agent.

Agent prompt:
```
You are the test-strategist agent.

Feature/Release: {{FEATURE}}

Risk analysis from Stage 1:
{{RISK_OUTPUT}}

Read qa.config.md for environment details and DoD.

Design the complete test case set:

For EACH area marked P0 or P1 in the risk analysis, write:

**Test Case ID:** TC-001
**Area:** [e.g. User Authentication]
**Type:** [Unit | Integration | E2E | Manual]
**Priority:** [P0 | P1 | P2]
**Preconditions:** [what must be true before the test runs]
**Steps:**
  1. [step]
  2. [step]
**Expected Result:** [what success looks like]
**Data Requirements:** [test data needed]
**Automatable:** [Yes / No — reason if No]

Cover:
- Happy path (every main flow)
- Boundary conditions (min/max values, empty states)
- Negative cases (invalid input, missing auth, server errors)
- Edge cases identified in risk analysis

Write at minimum:
- All P0 test cases (exhaustive)
- Key P1 test cases
- Brief descriptions for P2 (not full cases)

Format as a structured test plan document suitable for {{TEST_MGMT}}.
```
Tools: Read

Gate: Print test case summary (total count per type/priority). Ask "Proceed to AUTOMATION + PERFORMANCE? [y/N]"

---

### Stage 3 — AUTOMATION  ← spawn in PARALLEL with Stage 4
Spawn the `automation-engineer` agent.

Agent prompt:
```
You are the automation-engineer agent.

Feature/Release: {{FEATURE}}

Test cases from Stage 2:
{{PLAN_OUTPUT}}

Read qa.config.md for the test framework: {{E2E_FRAMEWORK}}

From the test cases, select all marked "Automatable: Yes" and write the automation code.

For E2E tests ({{E2E_FRAMEWORK}}):
- Use page objects / app actions pattern (never put selectors in test files)
- All selectors use data-testid attributes
- No sleep() — use explicit waits for conditions
- Each test is fully independent (no shared state with other tests)
- Clean up test data after each test

For API/integration tests:
- Test all happy path responses (correct status code + response shape)
- Test all error responses (400, 401, 403, 404, 500)
- Use test fixtures for request bodies
- Assert both status code AND response body structure

Write:
1. Page object / service files (one per major page or API resource)
2. Test spec files (one per feature area)
3. Test fixture files (shared test data)
4. CI config snippet for running these tests

Write production-ready code. No TODOs. No pseudocode.
```
Tools: Read, Write, Edit, Glob

---

### Stage 4 — PERFORMANCE TEST PLAN  ← spawn in PARALLEL with Stage 3
Spawn the `performance-tester` agent.

Agent prompt:
```
You are the performance-tester agent.

Feature/Release: {{FEATURE}}

Read qa.config.md for: {{PERF_FRAMEWORK}}

Design the performance test plan for this feature.

1. **SLO Definition** — for each endpoint/flow:
   | Endpoint | Throughput Target | P95 Latency | P99 Latency | Error Rate |
   |----------|------------------|-------------|-------------|------------|
   | [path]   | [N req/s]        | [<Xms]      | [<Xms]      | [<0.1%]    |

   If SLOs are not defined, recommend sensible defaults based on feature type:
   - Auth endpoints: < 200ms P95, < 500ms P99
   - Read APIs: < 100ms P95, < 300ms P99
   - Write APIs: < 300ms P95, < 800ms P99
   - File upload/export: < 5s P95

2. **Test scenarios** (write scripts for {{PERF_FRAMEWORK}}):
   - Smoke test: 1 VU, 1 min — verifies script runs
   - Load test: [expected concurrent users], 15 min — steady state
   - Spike test: ramp from 0 to 10× normal in 30 seconds — find breaking point
   - Soak test: expected load for 30 min — memory leaks, degradation

3. **Analysis checklist** for interpreting results:
   - Pass/fail verdict per SLO
   - P50/P95/P99/max latency
   - Throughput vs target
   - Error rate
   - System resource utilisation (CPU, memory, DB connections)

Write the performance test script file(s) with inline comments.
```
Tools: Read, Write

After both Stage 3 and Stage 4 complete, print combined outputs.
Gate: Ask "Proceed to TEST PLAN DOCUMENT? [y/N]"

---

### Stage 5 — DOCUMENT & TICKET
Spawn the `qa-lead` agent.

Agent prompt:
```
You are the qa-lead agent.

Feature/Release: {{FEATURE}}

Test plan and automation from previous stages:
{{PLAN_OUTPUT}}
{{AUTOMATION_OUTPUT}}

Read qa.config.md:
  - ticket_system: {{TICKET_SYSTEM}}
  - docs_platform: {{DOCS_PLATFORM}}
  - test_management: {{TEST_MGMT}}

Produce:

1. **Final test plan document** formatted for {{DOCS_PLATFORM}}:
   - Executive summary (what is being tested, why, risk level)
   - Scope and out-of-scope
   - Test approach and environment details
   - Test case summary table (ID, description, type, priority, status)
   - Automation coverage (automated vs manual ratio)
   - Performance SLOs
   - Entry and exit criteria
   - Sign-off section

2. **Ticket creation instructions** for {{TICKET_SYSTEM}}:
   For each P0 test case not yet automated, write:
   "Create ticket: [summary] | Type: QA Task | Priority: [P0/P1]"
   
   For any test infrastructure setup needed:
   "Create ticket: [summary] | Type: Technical Task"

3. **DoD checklist** for this feature:
   Based on qa.config.md definition_of_done, confirm each item is addressed.

Format the test plan document so it can be pasted directly into {{DOCS_PLATFORM}}.
```
Tools: Read, Write

---

## Test Plan Summary Report

After all stages complete, print:

```
════════════════════════════════════════════════════════
  QA Test Plan — {{FEATURE}}
════════════════════════════════════════════════════════
  [✓] Stage 1 — RISK ANALYSIS     High-risk areas: [N]
  [✓] Stage 2 — TEST DESIGN       Test cases: [N total — P0:N P1:N P2:N]
  [✓] Stage 3 — AUTOMATION        Automated: [N cases, N files]
  [✓] Stage 4 — PERFORMANCE       SLOs defined: [N endpoints]
  [✓] Stage 5 — DOCUMENTED        Plan ready for: {{DOCS_PLATFORM}}
════════════════════════════════════════════════════════

Test coverage:
  P0 (must test): [N] — [N automated, N manual]
  P1 (should):    [N] — [N automated, N manual]
  P2 (nice):      [N] — documented only

Tickets to create in {{TICKET_SYSTEM}}:
  [list any P0/P1 manual test tasks]
```

---

## Variables

- `{{FEATURE}}` = argument passed to this command
- `{{RISK_OUTPUT}}` = Stage 1 agent output (first 3000 chars)
- `{{PLAN_OUTPUT}}` = Stage 2 agent output (first 3000 chars)
- `{{AUTOMATION_OUTPUT}}` = Stage 3 agent output summary
- `{{E2E_FRAMEWORK}}` = from qa.config.md
- `{{PERF_FRAMEWORK}}` = from qa.config.md
- `{{TEST_MGMT}}` = from qa.config.md
- `{{TICKET_SYSTEM}}` = from workflow.config.md
- `{{DOCS_PLATFORM}}` = from workflow.config.md
