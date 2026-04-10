---
user-invocable: true
description: Service deployment checklist and CI/CD pipeline review
allowed-tools: Read, Bash, Glob, Grep
---

# Service Deployment Workflow

1. Spawn `devops-advisor` to review Dockerfile, CI config, and K8s/Helm manifests
2. Verify deployment safety checklist (health checks, probes, resource limits, rollback plan)
3. Check migration safety (run before app pods start)
4. Review secrets handling (no hardcoded credentials in manifests)
5. Output: Go/No-Go for deployment with specific items to address
