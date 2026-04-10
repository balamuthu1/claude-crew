# Jira Flow — Quick Reference

A reference for interacting with Jira through Claude using the `jira-advisor` agent and Jira CLI.

---

## Setup

```bash
# Install Jira CLI
brew install ankitpokhrel/jira-cli/jira-cli   # macOS
# Linux/Windows: https://github.com/ankitpokhrel/jira-cli/releases

# Connect to your Jira instance
jira init

# Verify connection
jira me
```

Run `/detect-jira` once per project to generate `jira.config.md`.

---

## Daily Workflow

### Morning: What should I work on?

```
"Show me the active sprint"
"What are my assigned tickets?"
"Show high priority items in the backlog"
```

CLI equivalents:
```bash
jira issue list --project PROJ --sprint active --order-by priority
jira issue list --project PROJ --sprint active --assignee "$(jira me --raw | jq -r '.name')"
```

### Starting a ticket

```
"Start PROJ-123"                           # transitions to In Progress
"What does PROJ-123 involve?"              # shows full issue details
"Create a branch for PROJ-123"             # suggests branch name from git-flow config
```

CLI:
```bash
jira issue move PROJ-123 "In Progress"
jira issue view PROJ-123
git checkout -b feature/PROJ-123-dark-mode
```

### Opening a PR

```
"Move PROJ-123 to In Review"
"What's the PR title for PROJ-123?"
```

CLI:
```bash
jira issue move PROJ-123 "In Review"
```

### Finishing work

```
"Mark PROJ-123 as Done"
"Move PROJ-123 to QA"
```

CLI:
```bash
jira issue move PROJ-123 "Done"
```

---

## Creating Tickets

### New story / feature

```
"Create a story for adding biometric login to the Android app"
"Create a Bug: crash on login when device has no biometrics"
"Create a Spike to investigate Compose animation performance"
```

CLI (interactive):
```bash
jira issue create --project PROJ --type Story
```

### Breaking down an epic

```
"Break epic PROJ-100 into stories for the Android and iOS teams"
"List the stories under epic PROJ-100"
```

CLI:
```bash
jira epic list --project PROJ
jira issue list --project PROJ --epics PROJ-100
```

---

## Sprint Planning

### Current sprint state

```
"Show sprint burndown"
"Which tickets have no estimate?"
"What's still in To Do?"
```

CLI:
```bash
jira sprint list --project PROJ
jira issue list --project PROJ --sprint active --status "To Do"
```

### Backlog refinement

```
"List unrefined backlog items"
"Which stories have no acceptance criteria?"
"Estimate PROJ-123 — it's adding a Settings screen with 3 toggles"
```

CLI:
```bash
jira issue list --project PROJ --status "Backlog" --no-headers
```

---

## Ticket Reference Quick Guide

| Format | Example | Use in |
|---|---|---|
| `PROJ-123` | `PROJ-123` | Branch names, commit messages, PR titles |
| Jira link | `https://org.atlassian.net/browse/PROJ-123` | PR descriptions, Slack |
| Commit ref | `feat(android): add login PROJ-123` | Commit messages |
| Footer | `Refs: PROJ-123` | Commit body |

---

## Branch → Ticket Linking

The `jira-advisor` automatically extracts Jira ticket IDs from:

- **Branch names**: `feature/PROJ-123-dark-mode` → PROJ-123
- **Commit messages**: any `[A-Z]+-[0-9]+` pattern
- **PR titles**: leading `PROJ-123:` prefix

To show the Jira link for the current branch:
```
"What Jira ticket is the current branch?"
```

---

## Common Jira CLI Commands

```bash
# Project
jira project list

# Issues
jira issue list --project PROJ --sprint active
jira issue view PROJ-123
jira issue create --project PROJ --type Story --summary "..."
jira issue move PROJ-123 "In Progress"
jira issue assign PROJ-123 --assignee "me"

# Epics
jira epic list --project PROJ
jira epic create --project PROJ --summary "..."

# Sprints & Boards
jira sprint list --project PROJ
jira board list --project PROJ

# Account
jira me
```

---

## Useful Filters

```bash
# My open tickets this sprint
jira issue list --project PROJ --sprint active --assignee me --status "!Done"

# Unassigned in sprint
jira issue list --project PROJ --sprint active --assignee "" 

# Bugs in backlog
jira issue list --project PROJ --type Bug --status "To Do"

# All blockers
jira issue list --project PROJ --priority Blocker

# Recently updated
jira issue list --project PROJ --updated-after "2025-04-01"
```

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `jira: command not found` | Install: `brew install ankitpokhrel/jira-cli/jira-cli` |
| `unauthorized` or 401 | Re-run `jira init` with correct credentials |
| Wrong project / board | Edit `jira.config.md` or re-run `/detect-jira` |
| Status name mismatch | Check exact names with `jira issue view PROJ-123` and update `jira.config.md` |
| Missing custom field | Add field name to `jira.config.md` notes section |
