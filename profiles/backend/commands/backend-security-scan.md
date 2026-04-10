---
description: Full OWASP API Security Top 10 audit plus secrets scan for the backend codebase.
---

Spawn `backend-security` with instruction to perform a full security audit:
1. OWASP API Security Top 10 scan across all controller and service files
2. Secrets scan — look for hardcoded credentials, API keys, connection strings
3. Auth review — JWT validation, token storage, session management
4. Dependency audit — flag any known vulnerable packages

Output a structured report with Critical / High / Medium / Informational findings.
