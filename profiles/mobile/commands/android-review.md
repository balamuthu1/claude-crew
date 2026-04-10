---
name: android-review
description: >
  Slash command: /android-review
  Triggers a full Android code review using the android-reviewer agent.
  Usage: /android-review [file or PR description]
---

Invoke the `android-reviewer` agent to perform a comprehensive Android/Kotlin code review.

If a file path or code snippet was provided, review that specific code.
If no argument is given, ask the user which files or PR they want reviewed.

Apply all rules from `rules/kotlin.md` and `rules/android-architecture.md`.

Output a structured review with Critical, Major, Minor sections and Positive Observations.
