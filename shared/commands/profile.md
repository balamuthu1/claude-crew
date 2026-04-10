---
description: Manage active team profiles. Usage: /profile [list|status|use <name>|add <name>|remove <name>]
---

Run directly — do not spawn a sub-agent.

## What profiles do

Claude Crew supports multiple team disciplines, each with specialist agents, commands, skills,
and security guardrails. The active profile set controls which agents Claude routes work to.

Available profiles:

| Profile    | Specialists |
|------------|-------------|
| `mobile`   | Android & iOS developers, reviewers, architect, security, test, a11y, release |
| `backend`  | API developer, backend architect, DB specialist, DevOps advisor, security, test |
| `qa`       | Test strategist, automation engineer, performance tester, bug triager, QA lead |
| `product`  | PRD author, user story writer, product manager, metrics analyst, stakeholder advisor |
| `data`     | Data engineer, ML engineer, analytics engineer, SQL specialist, data reviewer |
| `frontend` | Frontend developer, reviewer, UI engineer, accessibility auditor, architect |

---

## Step 1 — Detect action

Parse the user's argument:
- `list` or no argument → **list** all profiles with active/installed status (Step 2a)
- `status` → **show** active profiles and their agent roster (Step 2b)
- `use <name>` → **replace** active set with a single profile (Step 2c)
- `add <name>` → **add** profile to active set (Step 2d)
- `remove <name>` → **remove** profile from active set (Step 2e)

---

## Step 2a — List profiles

Read `.claude/ACTIVE_PROFILES` (if it exists) to know which profiles are active.
Read `.claude/INSTALLED_PROFILES` (if it exists) to know which are installed.

Display:

```
Claude Crew — Profiles

  mobile   [active] [installed]   Android & iOS mobile engineering
  backend  [installed]            API, database, infrastructure
  qa       -                      Testing, automation, quality assurance
  product  -                      PRD, user stories, roadmaps
  data     -                      Pipelines, ML, analytics, SQL
  frontend -                      Web UI, components, accessibility

Active: mobile
To activate: /profile add <name>
To install:  re-run install.sh --profile <name>
```

Mark each profile with `[active]` if in ACTIVE_PROFILES, `[installed]` if in INSTALLED_PROFILES.
If neither file exists, assume only `mobile` is installed and active.

---

## Step 2b — Status

Read `.claude/ACTIVE_PROFILES`. For each active profile, list its agents:

```
Active profiles: mobile

  mobile
    Agents: android-developer, ios-developer, android-reviewer, ios-reviewer,
            mobile-architect, mobile-performance, mobile-security,
            mobile-test-planner, release-manager, ui-accessibility
    Commands: /sdlc, /android-review, /ios-review, /mobile-test,
              /mobile-release, /detect-arch, /security-scan

  (+ shared agents always active: git-flow-advisor, jira-advisor, scrum-master, learning-agent)

To add a profile:    /profile add <name>
To switch profiles:  /profile use <name>
```

---

## Step 2c — Use `<name>` (replace active set)

1. Validate `<name>` is one of: mobile, backend, qa, product, data, frontend.
   If invalid, show the list and exit.

2. Check `.claude/INSTALLED_PROFILES` — if `<name>` is not installed, warn:
   ```
   ⚠  Profile 'backend' is not installed.
   Run: bash install.sh --profile backend
   The ACTIVE_PROFILES file will still be updated, but the agents won't be
   available until you run the installer.
   ```

3. Write `.claude/ACTIVE_PROFILES` with only `<name>` (single line).

4. Confirm:
   ```
   ✓ Active profile set to: backend
   All agent dispatch now routes to backend specialists.
   Run /profile status to see the full agent roster.
   ```

---

## Step 2d — Add `<name>`

1. Validate `<name>`.

2. Read `.claude/ACTIVE_PROFILES`. If `<name>` is already listed, say so and exit.

3. Check for conflicts: read `profiles/<name>/profile.json` if accessible and check
   `conflictsWith` array. If any currently active profile is listed there, warn:
   ```
   ⚠  Profile '<name>' declares a conflict with currently active profile '<other>'.
   Adding it anyway — check the docs if agents behave unexpectedly.
   ```

4. Append `<name>` to `.claude/ACTIVE_PROFILES`.

5. Check `.claude/INSTALLED_PROFILES` — if not installed, show install warning.

6. Confirm:
   ```
   ✓ Added profile: qa
   Active profiles: mobile, qa

   New agents available: test-strategist, automation-engineer,
                         performance-tester, bug-triager, qa-lead
   New commands: /test-plan, /bug-report, /regression-suite,
                 /performance-test, /qa-review
   ```

---

## Step 2e — Remove `<name>`

1. Read `.claude/ACTIVE_PROFILES`.

2. If `<name>` is not currently active, say so and exit.

3. If removing would leave zero active profiles, refuse:
   ```
   ✗ Cannot remove '<name>' — it is the only active profile.
   Add another profile first: /profile add <other>
   ```

4. Remove `<name>` from the list. Write the updated list back to `.claude/ACTIVE_PROFILES`.

5. Confirm:
   ```
   ✓ Removed profile: qa
   Active profiles: mobile
   ```
