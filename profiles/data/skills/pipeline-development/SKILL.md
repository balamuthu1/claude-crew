---
user-invocable: true
description: Build a new data pipeline end-to-end — design, implement, test, and set up monitoring
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Pipeline Development Workflow

1. Spawn `data-engineer` to design the pipeline (source, transform, target, scheduling)
2. Implement: extraction, transformation, loading, idempotency, error handling
3. Write data quality checks at pipeline boundaries
4. Set up observability: row count metrics, freshness alerts, dead letter queue
5. Spawn `data-reviewer` for review
6. Output: complete pipeline implementation + runbook
