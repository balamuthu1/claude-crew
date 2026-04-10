---
user-invocable: true
description: Full backend code review workflow — API design, database, security, and test coverage
allowed-tools: Read, Grep, Glob, Write, Edit
---

# Backend Code Review Workflow

1. Read `backend.config.md` and `profiles/backend/rules/` for review standards
2. Spawn `api-reviewer` for code quality review
3. Spawn `backend-security` for OWASP API security audit
4. Spawn `database-specialist` if migrations or queries are included
5. Present combined report: Critical → Major → Minor → Approved patterns
