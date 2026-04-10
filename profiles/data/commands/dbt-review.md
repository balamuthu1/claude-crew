---
description: Review dbt models for SQL correctness, layer conventions, test coverage, and documentation completeness. Spawns data-reviewer.
---

Spawn `data-reviewer` with the dbt model file paths.

Review covers:
1. Layer conventions (staging/intermediate/mart)
2. SQL correctness and style
3. YAML schema completeness (column descriptions, tests)
4. Test coverage (not_null, unique, accepted_values, relationships)
5. Model documentation
6. Performance (avoid SELECT *, expensive operations)
