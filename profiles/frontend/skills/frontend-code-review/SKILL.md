---
user-invocable: true
description: Full frontend code review — TypeScript, component quality, security, and accessibility
allowed-tools: Read, Grep, Glob, Write, Edit
---

# Frontend Code Review Workflow

1. Spawn `frontend-reviewer` for code quality (TypeScript, component patterns, performance)
2. Spawn `accessibility-auditor` for WCAG 2.1 AA audit
3. Review security (XSS, token storage, CSP)
4. Combined report: Critical → Major → Minor
