Detect the team's git conventions from the repository and write `git-flow.config.md`.

Spawn the `git-flow-advisor` agent with this task:

```
You are the git-flow-advisor agent performing auto-detection.

Read the repository to infer the team's git conventions, then write git-flow.config.md.

## Step 1 — Inspect the repo

Run these commands and collect the output:

git branch -a
git log --format="%D" --simplify-by-decoration | head -30
git log --format="%s" -100
git tag --sort=-version:refname | head -20
git remote -v

Also read these files if they exist:
- CONTRIBUTING.md
- .github/pull_request_template.md
- .gitmessage
- CHANGELOG.md (first 50 lines)
- .gitconfig (project-level)
- fastlane/Fastfile (for release lane names)

## Step 2 — Detect each convention

For each field in git-flow.config.md, infer from evidence:

**Strategy** — look at branch names:
- branches named "develop" or "dev" → gitflow
- only main/feature branches → github-flow
- mostly trunk with short-lived branches → trunk-based

**Branch naming** — sample 20+ branch names, find the pattern:
- Extract prefix (feature/, feat/, f/, bugfix/, fix/, etc.)
- Extract ticket format (ABC-123, #42, PROJ-123, etc.)
- Derive the branch-pattern template

**Commit style** — sample 50+ commit messages:
- "feat(scope): message" → conventional
- "[PROJ-123] message" → custom with ticket prefix
- "Add feature X" → no convention, use conventional as default

**Commit types** — list all distinct type prefixes found

**Commit scopes** — list all distinct scopes found in (scope) position

**Versioning** — look at git tags:
- v1.2.3 → semver
- 2025.04.1 → calver
- build-123 → build-number only

**Sprint branches** — look for sprint/* or iteration/* branches

**Protected branches** — note main, master, develop, release/*

## Step 3 — Write git-flow.config.md

Write the file to the project root with:
- All detected values filled in with confidence (✓ detected / ? inferred / - not found)
- A comment next to each value indicating how it was detected
- The legacy-notes section summarizing any unusual patterns found

## Step 4 — Report

Print a summary:
```
## Git Flow Detection Complete

strategy: gitflow (✓ develop branch found)
branch-pattern: feature/{ticket}-{description} (✓ from 12 branches)
commit-style: conventional (✓ from 45/50 recent commits)
commit-types: feat, fix, chore, docs, refactor (✓ detected)
commit-scopes: android, ios, api, ci (✓ detected)
versioning: semver (✓ tags: v2.3.1, v2.3.0, v2.2.5)
sprint-branches: none detected

Review git-flow.config.md and edit anything the detector got wrong.
```
```

If `git-flow.config.md` already exists, ask before overwriting:
"git-flow.config.md already exists. Overwrite? [y/N]"
