Generate a complete performance test suite for the endpoint or feature described in the argument.

You are the **orchestrator**. Do NOT write tests yourself — spawn dedicated sub-agents.

---

## Before starting

Read `qa.config.md` and `workflow.config.md`. Extract:
- `{{PERF_FRAMEWORK}}` — k6, Gatling, Locust, JMeter, etc.
- `{{TICKET_SYSTEM}}` — from workflow.config.md
- `{{DOCS_PLATFORM}}` — from workflow.config.md

---

## Stage Definitions

### Stage 1 — SLO DEFINITION
Spawn the `performance-tester` agent.

Agent prompt:
```
You are the performance-tester agent.

Feature / endpoint: {{FEATURE}}
Performance framework: {{PERF_FRAMEWORK}}

Read qa.config.md. Check if SLOs are already defined. If not, define them now.

1. **Identify all endpoints/flows** in this feature:
   For each user-facing interaction, list the HTTP endpoint or flow name.

2. **Define SLOs** for each endpoint/flow:

   | Endpoint/Flow | Expected RPS | P50 | P95 | P99 | Max | Error Rate |
   |---|---|---|---|---|---|---|

   If SLOs are not provided, apply these defaults based on endpoint type:

   | Endpoint type | P95 target | P99 target | Error rate |
   |---|---|---|---|
   | Authentication (login, token refresh) | < 200ms | < 500ms | < 0.1% |
   | Simple read (GET single resource) | < 100ms | < 300ms | < 0.1% |
   | List/search (paginated collection) | < 200ms | < 500ms | < 0.1% |
   | Simple write (POST/PUT/PATCH) | < 300ms | < 800ms | < 0.5% |
   | Complex write (multi-table transaction) | < 500ms | < 1500ms | < 0.5% |
   | File upload (< 10MB) | < 2s | < 5s | < 1% |
   | File export / report generation | < 5s | < 15s | < 1% |
   | Search with full-text / complex filters | < 500ms | < 1s | < 0.1% |
   | Background job trigger (async) | < 200ms | < 500ms | < 0.1% |

3. **Expected load profile**:
   - Normal concurrent users: N
   - Peak concurrent users: N (typically 3–5× normal)
   - Daily traffic pattern: constant / business hours / event-driven spike?

4. **Test environment considerations**:
   - Is the test environment sized similarly to production? (note differences)
   - Is test data pre-seeded? (auth accounts, existing records)
   - Any rate limits that would block the test before finding real limits?

Output: SLO table + load profile. If SLOs already exist in qa.config.md, confirm them.
```
Tools: Read, Glob

Gate: Print SLO table. Ask "SLOs confirmed? Proceed to WRITE TEST SCRIPTS? [y/N]"

---

### Stage 2 — WRITE TEST SCRIPTS
Spawn the `performance-tester` agent.

Agent prompt:
```
You are the performance-tester agent.

Feature / endpoint: {{FEATURE}}
Performance framework: {{PERF_FRAMEWORK}}
SLOs from Stage 1: {{SLO_OUTPUT}}

Write complete {{PERF_FRAMEWORK}} test scripts for FOUR scenarios.
All scripts must be production-ready — no TODOs, no pseudocode.

---

SCENARIO 1: SMOKE TEST
Purpose: verify the test script itself works before running real load.
Config: 1 VU, 60 seconds.
Pass criteria: 0 errors, all checks pass.

---

SCENARIO 2: LOAD TEST
Purpose: validate performance under normal expected load.
Config:
- Ramp up: 0 → N VUs over 2 minutes
- Steady state: N VUs for 10 minutes
- Ramp down: N → 0 VUs over 2 minutes
Pass criteria: all SLOs from Stage 1 met.

---

SCENARIO 3: SPIKE TEST
Purpose: find the breaking point under sudden traffic surge.
Config:
- Baseline: N VUs for 1 minute
- Spike: ramp to 10×N VUs over 30 seconds
- Hold spike: 2 minutes
- Ramp down: 30 seconds
- Recovery: hold baseline for 2 more minutes
Observe: at what VU count do errors start? What is recovery behaviour?

---

SCENARIO 4: SOAK TEST
Purpose: find memory leaks, connection pool exhaustion, or performance degradation over time.
Config: N VUs (normal load) for 30 minutes.
Pass criteria: P95 latency at minute 30 ≤ P95 latency at minute 5 (no degradation).

---

For ALL scripts, include:

**Authentication**: log in once per VU at startup; reuse session/token for all requests.
Do NOT authenticate on every request — this skews latency numbers.

**Dynamic test data**: use randomised or parameterised data.
Hammering the same single record skews cache performance. Use a pool of test entities.

**Think time**: add realistic user pause between requests (0.5–2s for API flows).

**Response validation** (not just HTTP 200 — also check response body):
- Assert status code is in expected range
- Assert response body has expected structure (check key fields exist)
- Assert no error messages in the response body
- Assert response time below a warn threshold (separate from SLO)

**Threshold definitions** (auto-fail the test if SLOs are breached):
For each endpoint: define threshold statements that cause the test to exit with failure
if SLOs are violated (e.g. p95 > 300ms → fail).

---

For k6 scripts, structure:
```js
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');
const endpointLatency = new Trend('endpoint_latency');

// Test configuration
export const options = { ... };

// Setup (runs once per test, not per VU)
export function setup() { ... }

// Main scenario function
export default function(data) { ... }

// Teardown
export function teardown(data) { ... }
```

For Locust (Python) scripts, structure:
```python
from locust import HttpUser, task, between
class FeatureUser(HttpUser):
    wait_time = between(0.5, 2.0)
    def on_start(self): ...  # auth
    @task(weight=3)
    def main_flow(self): ...
    @task(weight=1)
    def secondary_flow(self): ...
```

Write all four scenario scripts as separate files.
List each file path.
```
Tools: Read, Write

Gate: Print list of files written. Ask "Test scripts look good? Proceed to ANALYSIS GUIDE? [y/N]"

---

### Stage 3 — ANALYSIS GUIDE
Spawn the `performance-tester` agent.

Agent prompt:
```
You are the performance-tester agent.

Feature: {{FEATURE}}
SLOs: {{SLO_OUTPUT}}
Docs platform: {{DOCS_PLATFORM}}

Write a complete results interpretation guide:

1. **How to run the tests**:
   - Pre-conditions: test environment URL, auth credentials location, seed data script
   - Commands to run each scenario (in order: smoke → load → soak → spike)
   - Output location and how to read the results

2. **Pass/fail verdict checklist** (fill in after each run):
   - [ ] Smoke: 0 errors, all checks pass
   - [ ] Load: P95 within SLO for each endpoint
   - [ ] Load: P99 within SLO for each endpoint
   - [ ] Load: error rate < threshold
   - [ ] Load: throughput target achieved
   - [ ] Soak: no latency degradation over 30 minutes
   - [ ] Soak: no memory growth pattern in server metrics
   - [ ] Spike: system recovers within 2 minutes of spike ending

3. **Common failure patterns and root causes**:

   | Symptom | Likely cause | Investigation step |
   |---|---|---|
   | P95 high, P50 normal | Tail latency: GC pause, lock contention, or slow DB query | Check slow query log; review GC metrics |
   | Error rate spikes at peak | Connection pool exhausted; rate limit hit; OOM | Check connection pool metrics; app error logs |
   | Latency grows during soak | Memory leak; unbounded cache; connection leak | Heap dump at minute 5 vs minute 25 |
   | Spike: requests fail immediately | No connection queue; circuit breaker threshold too low | Adjust circuit breaker settings; add queue |
   | Spike: no recovery after spike | Thread pool not releasing; deadlock | Thread dump during recovery phase |
   | High P99 with low error rate | Outlier requests hitting cold cache or slow DB path | Distributed trace the P99 requests |

4. **System resource metrics to capture** during load test:
   - CPU utilisation (server and database)
   - Memory usage (heap, total)
   - Database connection pool: active / idle / waiting
   - Database slow query count
   - JVM GC pause time (if Java)
   - HTTP connection pool (for outbound calls)

5. **CI integration**:
   - Add performance gate to post-deploy CI stage (not every PR — only on staging/main)
   - Recommended: run smoke test on every deploy; run full load test nightly
   - Alert condition: if P95 increases by > 20% vs previous baseline

6. **Baseline establishment**:
   "Before enabling this feature for all users, run the load test N times on consecutive days
   to establish a performance baseline. Gate the full rollout on: P95 within SLO for 3
   consecutive runs."

Format the guide for {{DOCS_PLATFORM}}.
```
Tools: Read, Write

---

## Performance Test Summary Report

After all stages complete, print:

```
════════════════════════════════════════════════════════
  Performance Test — {{FEATURE}}
════════════════════════════════════════════════════════
  [✓] Stage 1 — SLOs DEFINED    Endpoints: N, SLOs set
  [✓] Stage 2 — SCRIPTS WRITTEN Smoke, Load, Spike, Soak (4 files)
  [✓] Stage 3 — GUIDE WRITTEN   Analysis guide for {{DOCS_PLATFORM}}
════════════════════════════════════════════════════════

SLO targets:
  [table from Stage 1]

Run order:
  1. Smoke:  [command]
  2. Load:   [command]
  3. Soak:   [command]
  4. Spike:  [command]

Next steps:
  [ ] Run smoke test first to confirm script works
  [ ] Run load test on staging after next deploy
  [ ] Create ticket in {{TICKET_SYSTEM}} if any SLO is missed
```

---

## Variables

- `{{FEATURE}}` = argument passed to this command
- `{{SLO_OUTPUT}}` = Stage 1 SLO table (first 2000 chars)
- `{{PERF_FRAMEWORK}}` = from qa.config.md
- `{{TICKET_SYSTEM}}`, `{{DOCS_PLATFORM}}` = from workflow.config.md
