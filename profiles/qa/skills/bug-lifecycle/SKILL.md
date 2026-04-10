---
user-invocable: true
description: Full bug lifecycle workflow — triage, root cause analysis, fix verification, and regression test
allowed-tools: Read, Grep, Glob, Bash
---

# Bug Lifecycle Workflow

1. Spawn `bug-triager` to classify the bug (severity, priority, root cause)
2. Produce structured bug report
3. Identify the fix approach
4. Spawn `automation-engineer` to write a regression test that would have caught this bug
5. Output: bug report + regression test + fix recommendation
