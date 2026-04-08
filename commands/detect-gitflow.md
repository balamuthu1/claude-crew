Detect the team's git conventions by asking key questions and inspecting the repository, then write `git-flow.config.md`.

Run the following steps directly — do not spawn a sub-agent.

---

## Step 1 — Inspect the repo silently

Run these commands and collect the output (do not print raw output to the user):

```
git branch -a
git log --format="%D" --simplify-by-decoration | head -30
git log --format="%s" -100
git tag --sort=-version:refname | head -20
```

Also read these files if they exist:
- CONTRIBUTING.md
- .github/pull_request_template.md
- .gitmessage
- CHANGELOG.md (first 50 lines)
- fastlane/Fastfile (for release lane names)

Form an initial inference for each field. Hold these as "detected defaults" — they will be proposed to the user in the next step.

---

## Step 2 — Ask the user key questions

Ask these questions **one section at a time**. Present each section with your detected default clearly shown. Wait for the user's answer before moving to the next section.

Use this format for each question:

```
[Section title]

  Detected: <value inferred from repo>
  <brief explanation of what you found>

  → <question asking for confirmation or correction>
     Options: <option1> | <option2> | ...  (or press Enter to accept detected)
```

**Questions to ask (in order):**

### Q1 — Branching Strategy
Show detected strategy. Ask:
"What branching strategy does your team use?"
Options: `gitflow` (main + develop + feature branches) | `github-flow` (main + feature branches only) | `trunk-based` (everyone commits to main/trunk) | `custom`

### Q2 — Main Branches
Show detected branch names. Ask:
"What is your production branch name?" (default: main or master, whatever was detected)
If strategy is gitflow, also ask: "What is your integration/develop branch name?" (default: develop or dev)

### Q3 — Branch Naming
Show 5 example branch names sampled from the repo. Ask:
"What prefix format do you use for feature branches?"
Examples: `feature/` | `feat/` | `f/` | none

Then ask:
"Do branch names include a ticket/issue ID? If yes, what format?"
Examples: `PROJ-123` (Jira) | `#42` (GitHub) | `123` (number only) | no ticket IDs

### Q4 — Commit Convention
Show 5 example commit messages sampled from the repo. Ask:
"What commit message style does your team use?"
Options: `conventional` (feat(scope): message) | `custom` | `none` (no enforced style)

If conventional or custom: "Which commit types does your team use?"
Suggest detected types and ask if they want to add or remove any.

### Q5 — Versioning
Show detected tags. Ask:
"What versioning scheme do you use?"
Options: `semver` (1.2.3) | `calver` (2025.04.1) | `build-number only` | `custom`

### Q6 — Sprint / Iteration Workflow
Ask:
"How long are your sprints?"
Options: `1 week` | `2 weeks` | `3 weeks` | `4 weeks` | `no sprints` (continuous flow)

Then ask:
"Do you use dedicated sprint branches (one branch per sprint that features branch from)?"
Options: `yes` | `no`

### Q7 — PR Conventions
Ask:
"What should a PR title look like?"
Show examples based on previous answers:
- If ticket: `PROJ-123: Add user profile screen`
- If conventional: `feat(android): add user profile screen`
- Custom: user types their own template

Then ask:
"What is the base branch for feature PRs?"
Options: detected develop/main branch names

### Q8 — Protected Branches
Show detected protected branches. Ask:
"Which branches should never be pushed to directly (protected)?"
Suggest: `main, develop` based on strategy. User can confirm or list their own.

---

## Step 3 — Confirm before writing

After all questions, print a summary of all values:

```
## Summary — git-flow.config.md

  strategy:           gitflow
  main-branch:        main
  develop-branch:     develop
  branch-pattern:     feature/{ticket}-{description}
  ticket-pattern:     [A-Z]+-[0-9]+
  commit-style:       conventional
  commit-types:       feat, fix, docs, refactor, test, chore, ci
  commit-scopes:      android, ios, shared, api, db, ui, auth, nav
  versioning:         semver
  sprint-duration:    2-weeks
  use-sprint-branches: false
  pr-title-format:    {ticket}: {description}
  pr-base-branch:     develop
  protected-branches: main, develop

Write git-flow.config.md with these values? [Y/n]
```

If the user says no, ask which values they want to change and loop back.

---

## Step 4 — Write git-flow.config.md

If `git-flow.config.md` already exists, warn the user and ask:
"git-flow.config.md already exists. Overwrite it? [y/N]"

Write the file with all confirmed values filled in. Add a confidence indicator comment next to each value:
- `# ✓ confirmed by user` — user explicitly answered
- `# ✓ detected from repo` — auto-detected and user accepted default
- `# ? inferred` — guessed, user did not explicitly confirm

---

## Step 5 — Report

Print:

```
## Git Flow Configuration Saved

git-flow.config.md written to project root.

Commit it so the whole team benefits:
  git add git-flow.config.md && git commit -m "chore: add git-flow.config.md"

Your agents (git-flow-advisor) will now:
  ✓ Generate correct branch names for your tickets
  ✓ Format commit messages in your style
  ✓ Know your sprint and release workflow

Try it:
  "Name a branch for ticket PROJ-42, adding dark mode support"
  "/sprint-start" to kick off your next sprint
```
