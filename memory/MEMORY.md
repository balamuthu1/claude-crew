# Claude Crew — Project Memory
#
# This file is read automatically at the start of every session.
# It accumulates learnings across all sessions so the harness becomes
# more accurate and project-aware over time.
#
# Written by: session-end hook, learning-agent, reviewer agents, and /learn command.
# Curated by: /memory-review (periodic housekeeping).
# Committed to git: YES — shared across the whole team.
#
# Entry format:
#   [YYYY-MM-DD | confidence:high/medium/low | source:who-wrote-this]
#   Content of the learning — be specific and actionable.
#
# confidence:high   → validated multiple times, used as a hard rule by agents
# confidence:medium → observed but not fully confirmed, used as a suggestion
# confidence:low    → extracted automatically, needs human validation
#
# To promote an entry: change confidence:low → medium → high
# To remove an entry: delete the line
# To correct an entry: edit inline — agents will use the updated version

---

## Architecture & Stack

<!-- Agents write here when they discover how the project is built.
     detect-arch auto-populates this section. -->

---

## Naming & Code Conventions

<!-- Agents write here when they notice consistent naming patterns.
     Reviewer agents write here when they find naming violations. -->

---

## Patterns & Best Practices

<!-- Agents write here when they identify project-specific patterns to follow. -->

---

## Antipatterns & Known Issues

<!-- Agents write here when they find patterns the team must AVOID.
     Security findings always go here. -->

---

## Team Preferences & Corrections

<!-- Written by session-end hook when it detects the user correcting Claude's output.
     Also written by explicit /learn calls. -->

---

## Git & Branching

<!-- git-flow-advisor writes here when it detects actual patterns in use. -->

---

## Jira & Sprint

<!-- jira-advisor and scrum-master write here. -->

---

## Security Notes

<!-- mobile-security and /security-scan write here. -->

---

## Build & CI

<!-- Written when build commands, CI patterns, or tooling is discovered. -->
