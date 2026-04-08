Kick off a new sprint following the team's declared git flow conventions.

Spawn the `git-flow-advisor` agent with this task:

```
You are the git-flow-advisor agent running the sprint-start workflow.

Argument: $ARGUMENTS

## Step 1 — Read config

Read git-flow.config.md and claude-crew.config.md from the project root.

If git-flow.config.md doesn't exist, tell the user to run /detect-gitflow first
and stop.

## Step 2 — Determine sprint identity

If a sprint number or date was provided in the argument, use it.
Otherwise:
- Run: git log --oneline -5 and git branch -a | grep sprint
- Infer the current sprint number or date from context
- Ask the user to confirm: "Starting Sprint [N] — correct? [Y/n]"

## Step 3 — Sync branches

Based on sprint-start-sync in config, produce and execute the sync commands:

git fetch --all --prune
git checkout {main-branch} && git pull origin {main-branch}
git checkout {develop-branch} && git pull origin {develop-branch}

Report: "✓ Synced main and develop"
Report any divergence (commits ahead/behind).

## Step 4 — Create sprint branch (if configured)

If use-sprint-branches: true:
- Generate sprint branch name from sprint-branch-pattern
  Tokens: {YYYY}, {MM}, {WW} (ISO week), {sprint-number}
- Run:
    git checkout {sprint-branch-base}
    git checkout -b {sprint-branch-name}
    git push -u origin {sprint-branch-name}
- Report: "✓ Created sprint branch: {sprint-branch-name}"

If use-sprint-branches: false, skip this step.

## Step 5 — Confirm version target

Based on versioning config and recent tags, suggest the version for this sprint:
- Show last 3 tags
- Propose next version (minor bump for new features, patch for bugfix-only sprint)
- Ask: "Planned version for this sprint: {proposed-version}? [Y/n]"

## Step 6 — Print sprint start checklist

Produce a ready-to-copy checklist tailored to the team's conventions:

---
## Sprint [N] Start — [date]

### Git
[✓] Synced main and develop
[✓] Created sprint/branch (if applicable)
[ ] Create feature branches for each ticket:
    git checkout {base} && git checkout -b {branch-pattern-example}

### Branch name reference
Pattern: {branch-pattern}
Example tickets this sprint:
  feature/PROJ-XXX-ticket-description
  bugfix/PROJ-XXX-ticket-description

### Commit message reference
Style: {commit-style}
Format: {type}({scope}): {summary}
Types:  {commit-types}
Scopes: {commit-scopes}

### PR checklist (each PR before merge)
[ ] Branch named correctly
[ ] Commits follow {commit-style} convention
[ ] PR title: {pr-title-format}
[ ] Base branch: {pr-base-branch}
[ ] CI passing
[ ] Self-reviewed

### Version target
Planned: {version} (bump when sprint closes)
Android: versionCode={current+1}, versionName={version}
iOS:     CFBundleVersion={current+1}, MARKETING_VERSION={version}
---
```
