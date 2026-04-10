---
description: Review SQL queries or dbt models for correctness, performance, and style. Spawns sql-specialist.
---

Spawn `sql-specialist` with the SQL file paths or inline SQL to review.

Review covers:
1. Query correctness (correct JOINs, aggregation grain, null handling)
2. Performance (missing indices, full scans, N+1, unbounded queries)
3. Style (CTEs, column qualification, naming)
4. Security (parameterisation, PII exposure)
