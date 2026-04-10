---
description: Review a data pipeline for correctness, idempotency, observability, and security. Spawns data-reviewer.
---

Spawn `data-reviewer` with the pipeline file paths.

Review covers:
1. Idempotency and incremental load correctness
2. Data quality checks
3. Error handling and dead letter queues
4. Schema evolution handling
5. Security (no hardcoded credentials, PII handling)
6. Observability (metrics, alerting)
