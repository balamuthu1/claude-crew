---
description: Review backend API code. Spawns api-reviewer for code quality, then backend-security for OWASP API Security Top 10 audit.
---

Spawn `api-reviewer` with the relevant files. If no files are specified, glob for recently changed files in the API/controller layer.

After the review completes, spawn `backend-security` in parallel with the same files for a security audit.

Present both reports together, prioritised by severity.
