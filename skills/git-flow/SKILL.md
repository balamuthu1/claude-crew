# Git Flow Workflow

This skill covers the team's complete git workflow. Always read `git-flow.config.md` first.

---

## Daily Workflow

### Starting a new task

1. Sync your base branch
```bash
git checkout develop    # or main for github-flow
git pull origin develop
```

2. Create a branch (ask `git-flow-advisor` for the exact name)
```bash
git checkout -b feature/PROJ-123-short-description
```

3. Work, commit often
```bash
git add -p              # stage selectively
git commit              # follow commit-style from config
```

4. Keep your branch up to date
```bash
git fetch origin
git rebase origin/develop   # prefer rebase over merge for feature branches
```

5. Push and open PR
```bash
git push -u origin feature/PROJ-123-short-description
```

---

## Commit Message Quick Reference

Format (conventional commits):
```
{type}({scope}): {summary}

{body — optional, explain why not what}

{footer — Closes PROJ-123, BREAKING CHANGE: ...}
```

**Types:** feat · fix · refactor · perf · test · docs · chore · ci · build · revert

**Scope:** android · ios · shared · api · db · ui · auth · nav · ci · release

**Rules:**
- Summary: present tense, no capital, no period, max 72 chars
- Body: wrap at 72 chars, blank line between subject and body
- Breaking change: add `!` → `feat(android)!:` + `BREAKING CHANGE:` footer

---

## Branch Naming Quick Reference

```
feature/PROJ-123-user-profile-screen     ← new feature
bugfix/PROJ-456-null-crash-on-startup    ← bug fix in sprint
hotfix/PROJ-789-payment-crash-prod       ← urgent prod fix
release/2.5.0                            ← release branch
chore/PROJ-321-update-dependencies       ← non-feature work
experiment/PROJ-444-new-nav-library      ← spike/exploration
```

Always lowercase-kebab-case in the description part. Strip filler words.

---

## Sprint Workflow

### Sprint start
```
/sprint-start [sprint number or date]
```
Or ask `git-flow-advisor`: "Sprint 47 is starting, what do I do?"

### During the sprint
- Branch every ticket from the sprint base branch
- Open draft PRs early for visibility
- Rebase on develop daily to avoid big merge conflicts
- Keep commits atomic — one logical change per commit

### Sprint end / closing
1. All feature branches merged to develop via PR
2. Verify CI is green on develop
3. If `use-sprint-branches: true`: merge sprint branch → develop
4. Tag if releasing: `git tag v{version}` on main after release merge

---

## Release Workflow

```bash
# 1. Branch from develop
git checkout develop && git pull
git checkout -b release/2.5.0

# 2. Bump version (do NOT add features)
#    Android: versionCode + versionName in app/build.gradle.kts
#    iOS: MARKETING_VERSION + CURRENT_PROJECT_VERSION

# 3. Fix release-blocking bugs only on this branch

# 4. Merge into main and tag
git checkout main && git merge --no-ff release/2.5.0
git tag v2.5.0
git push origin main --tags

# 5. Back-merge to develop
git checkout develop && git merge --no-ff release/2.5.0
git push origin develop

# 6. Delete release branch
git branch -d release/2.5.0
git push origin --delete release/2.5.0
```

---

## Hotfix Workflow

Use when a critical bug is in production and can't wait for the next sprint.

```bash
# 1. Branch from main (NOT develop)
git checkout main && git pull
git checkout -b hotfix/PROJ-999-crash-on-launch

# 2. Fix the bug, commit with fix type
git commit -m "fix(android): prevent NPE on cold start when user is null"

# 3. Bump patch version (2.4.0 → 2.4.1)

# 4. Merge into main and tag
git checkout main && git merge --no-ff hotfix/PROJ-999-crash-on-launch
git tag v2.4.1
git push origin main --tags

# 5. Back-merge to develop (critical: don't lose the fix)
git checkout develop && git merge --no-ff hotfix/PROJ-999-crash-on-launch
git push origin develop

# 6. Clean up
git branch -d hotfix/PROJ-999-crash-on-launch
git push origin --delete hotfix/PROJ-999-crash-on-launch
```

---

## PR Conventions

**Title:** `{ticket}: {short description}` (e.g. `PROJ-123: Add dark mode to settings`)

**Description template:**
```markdown
## What
One sentence summary of the change.

## Why
The problem or requirement this addresses.

## How
Key implementation decisions (not line-by-line).

## Test plan
- [ ] Tested on Android 14 (Pixel 8)
- [ ] Tested on iOS 17 (iPhone 15)
- [ ] Unit tests pass: ./gradlew test / xcodebuild test
- [ ] No new lint warnings

## Screenshots
[Attach before/after for any UI change]
```

**Before requesting review:**
- [ ] Branch named per convention
- [ ] All commits follow the declared commit style
- [ ] PR is rebased on latest develop (not behind)
- [ ] Self-reviewed the diff
- [ ] CI passing

---

## Common Git Commands Reference

```bash
# Undo last commit (keep changes staged)
git reset --soft HEAD~1

# Amend last commit message (before push only)
git commit --amend

# Interactive rebase to clean up commits before PR
git rebase -i origin/develop

# Stash work in progress
git stash push -m "WIP: dark mode toggle"
git stash pop

# See what changed between develop and your branch
git diff develop...HEAD

# Find which commit introduced a bug
git bisect start
git bisect bad HEAD
git bisect good v2.4.0

# Clean merged branches
git branch --merged develop | grep -v '^\*\|main\|develop' | xargs git branch -d
```
