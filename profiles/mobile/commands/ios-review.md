---
name: ios-review
description: >
  Slash command: /ios-review
  Triggers a full iOS code review using the ios-reviewer agent.
  Usage: /ios-review [file or PR description]
---

Invoke the `ios-reviewer` agent to perform a comprehensive Swift/iOS code review.

If a file path or code snippet was provided, review that specific code.
If no argument is given, ask the user which files or PR they want reviewed.

Apply all rules from `rules/swift.md` and `rules/ios-architecture.md`.

Output a structured review with Critical, Major, Minor sections and Positive Observations.
