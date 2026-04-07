---
name: mobile-release
description: >
  Slash command: /mobile-release
  Walks through the mobile release preparation checklist for Android and/or iOS.
  Usage: /mobile-release [version number]
---

Invoke the `release-manager` agent and follow the `skills/mobile-release.md` workflow.

1. Confirm the version number (ask if not provided).
2. Validate version code/name in build files.
3. Run through the full release checklist.
4. Generate user-facing release notes from recent commits or CHANGELOG.
5. Output a release summary with any blockers clearly flagged.
