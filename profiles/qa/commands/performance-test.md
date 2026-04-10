---
description: Generate a performance test script and SLO definition. Spawns performance-tester to write load tests and define performance baselines.
---

Spawn `performance-tester` with:
- Target endpoint or feature
- Expected load (requests/sec or concurrent users)
- SLO targets (if known)

Produces:
1. Performance SLO definition
2. Load test script (k6, JMeter, or Locust based on `qa.config.md`)
3. Ramp-up, steady-state, and spike scenarios
4. Analysis template for interpreting results
