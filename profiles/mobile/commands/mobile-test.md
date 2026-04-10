---
name: mobile-test
description: >
  Slash command: /mobile-test
  Generates a comprehensive test suite for the given Android or iOS feature/file.
  Usage: /mobile-test [feature name or file path]
---

Invoke the `mobile-test-planner` agent and follow the `skills/mobile-test.md` workflow.

1. Detect platform from the provided file extension or feature context.
2. Identify all testable units: ViewModel, UseCase, Repository, UI.
3. Generate complete test files with all setup, test cases, and mocks.
4. Output the test plan table plus ready-to-use test code.
