---
description: Generate or review a database migration. Spawns database-specialist to write safe up/down migrations with safety checklist.
---

Spawn `database-specialist` with:
- The schema change requested (or file path to review)
- Current database technology from `backend.config.md`

The specialist produces:
1. Migration file (up + down)
2. Safety checklist (table lock risk, backfill strategy, rollback plan)
3. Index recommendations
