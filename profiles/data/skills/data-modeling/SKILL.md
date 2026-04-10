---
user-invocable: true
description: Data modeling workflow — design schema, write migrations, build dbt models with tests
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Data Modeling Workflow

1. Spawn `database-specialist` or `data-engineer` based on context
2. Design the entity-relationship model
3. Write table definitions with constraints and indices
4. Write migration (up + down) with safety checklist
5. Build dbt models (staging → intermediate → mart)
6. Write dbt YAML schema with tests (not_null, unique, accepted_values)
7. Output: schema design + migration + dbt models + test coverage
