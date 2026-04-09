---
description: Stage changed files, commit following team conventions, push the branch, and open a pull request via gh CLI. Reads git-flow.config.md to apply the team's exact commit style, PR title format, and base branch.
---

Run the following steps directly — do not spawn a sub-agent.

## Step 1 — Read team conventions

Read these files before doing anything:
- `git-flow.config.md` (commit style, PR title format, base branch, ticket pattern)
- `jira.config.md` (if present — for ticket context)

If `git-flow.config.md` doesn't exist, use conventional commits defaults and note it.

---

## Step 2 — Inspect current state

Run silently (don't print raw output):

```bash
git status --short
git diff --stat HEAD
git branch --show-current
git log --oneline origin/$(git branch --show-current 2>/dev/null || echo main)..HEAD 2>/dev/null | head -10
git remote -v
```

Check:
- Are there staged or unstaged changes?
- What is the current branch name?
- Does the branch follow the team's `branch-pattern` from `git-flow.config.md`?
- Extract ticket ID from the branch name if `ticket-pattern` is defined
- Is `gh` CLI available? (`gh --version`)

---

## Step 3 — Confirm what will be committed

Show the user a summary:

```
Branch:  feature/PROJ-123-dark-mode-settings
Ticket:  PROJ-123  (extracted from branch)
Base:    develop   (from git-flow.config.md → pr-base-branch)

Changed files:
  M  app/src/main/.../SettingsViewModel.kt
  M  app/src/main/.../SettingsScreen.kt
  A  app/src/test/.../SettingsViewModelTest.kt

Proposed commit: feat(android): add dark mode toggle to settings screen

Proposed PR title: PROJ-123: add dark mode toggle to settings screen
```

Ask: **"Proceed with this commit message and PR title, or would you like to edit them?"**

Wait for confirmation before continuing. If the user wants to edit the message or title, apply their changes.

---

## Step 4 — Stage and commit

Stage all changed files (unless the user specified a subset):

```bash
git add -A
```

> **Security**: Before staging, check for sensitive files matching `.env`, `*.pem`, `*.jks`, `*.p12`, `*.keystore`, `google-services.json`, `GoogleService-Info.plist`. If any are staged, **stop and warn** — do not commit them.

Commit using the confirmed message:

```bash
git commit -m "<type>(<scope>): <summary>

<body if needed>

<footer: Closes TICKET if ticket was found>"
```

Follow the team's `commit-style` from `git-flow.config.md`:
- **conventional / angular**: `type(scope): summary` — use types from `commit-types`, scopes from `commit-scopes`
- **custom**: use `custom-commit-format`

If no ticket was found in the branch name and `require-ticket-in-branch` is `true`, warn the user but don't block.

---

## Step 5 — Push

```bash
git push -u origin $(git branch --show-current)
```

If the push is rejected (non-fast-forward), **stop and ask** the user how to proceed — never force push automatically.

---

## Step 6 — Create pull request via gh CLI

Check that `gh` is authenticated:
```bash
gh auth status
```

If not authenticated, instruct:
```
Run: gh auth login
Then retry /commit-push-pr
```

Build the PR using the team's conventions from `git-flow.config.md`:

**Title**: follow `pr-title-format`. Common patterns:
- `"{ticket}: {description}"` → `PROJ-123: add dark mode toggle to settings screen`
- `"feat(android): add dark mode toggle"` → type-scoped

**Base branch**: use `pr-base-branch` from config (default: `develop` for gitflow, `main` for github-flow).

**Body**: generate using this structure:

```markdown
## What
<one-sentence summary of the change>

## Why
<the problem this solves or the ticket requirement>

## How
<key implementation decisions — not line-by-line>

## Test plan
- [ ] <what the reviewer should manually verify>
- [ ] Unit tests pass: `./gradlew test` / `xcodebuild test`
- [ ] No new lint warnings

## Ticket
<link to Jira ticket if ticket ID found — read jira.config.md for the base URL>
```

Run:
```bash
gh pr create \
  --title "<PR title>" \
  --body "<PR body>" \
  --base <pr-base-branch> \
  --head $(git branch --show-current)
```

If `gh` is not available, print the PR details formatted for manual creation and provide the GitHub URL for the repo.

---

## Step 7 — Report result

Print a concise summary:

```
✓ Committed:  feat(android): add dark mode toggle to settings screen
✓ Pushed:     feature/PROJ-123-dark-mode-settings → origin
✓ PR opened:  https://github.com/org/repo/pull/42
              "PROJ-123: add dark mode toggle to settings screen"
              Base: develop

Next steps:
  • Assign reviewers on GitHub
  • Move PROJ-123 to "In Review" in Jira (or run /standup)
```

---

## Edge cases

| Situation | Behaviour |
|---|---|
| Nothing staged, nothing changed | Tell the user — nothing to commit |
| Already on a protected branch (main, develop) | Warn: "You are on a protected branch. Create a feature branch first." — do not commit |
| Branch has no upstream yet | `git push -u origin <branch>` — create it |
| `gh` not installed | Print PR details for manual creation, show install instructions: `brew install gh` |
| Sensitive file detected in changes | Block commit, list the files, explain why |
| Push rejected | Stop and explain — never force push automatically |
| PR already exists for this branch | Report the existing PR URL instead of creating a new one |
