---
description: Design a data model for a new entity or domain. Spawns database-specialist (or data-engineer for warehouse models) to produce schema, migrations, and documentation.
---

Determine the context:
- If transactional/application database → spawn `database-specialist`
- If data warehouse / dbt model → spawn `data-engineer`

Pass the entity description and relationships.

Produces:
1. Entity-relationship description
2. Table definitions with types, constraints, and indices
3. Migration file (for application databases)
4. dbt model YAML with tests (for warehouse models)
