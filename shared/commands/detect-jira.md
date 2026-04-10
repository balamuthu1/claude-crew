Set up the team's Jira configuration by asking key questions and inspecting the live Jira instance, then write `jira.config.md`.

Run the following steps directly — do not spawn a sub-agent.

---

## Step 0 — Check prerequisites

Run:
```bash
command -v jira && jira me 2>/dev/null || echo "NOT_READY"
```

**If `jira` is not installed**, tell the user:
```
Jira CLI is not installed. Install it first:

  macOS:   brew install ankitpokhrel/jira-cli/jira-cli
  Linux:   https://github.com/ankitpokhrel/jira-cli/releases
  Windows: https://github.com/ankitpokhrel/jira-cli/releases

After installing, run:
  jira init

Then run /detect-jira again.
```
Stop here.

**If `jira` is installed but not authenticated**, tell the user:
```
Jira CLI is installed but not connected to a Jira instance yet.
Run:  jira init

This will ask for your Jira URL and credentials.
Then run /detect-jira again.
```
Stop here.

**If connected**, greet the user:
```
Connected to Jira as: {name} ({email})
Instance: {jira-url}

I'll ask you a few questions to configure your Jira integration.
This creates jira.config.md — commit it so the whole team benefits.
```

---

## Step 1 — Detect project silently

Run these commands and collect output (do not print raw results to user):

```bash
jira project list --output json 2>/dev/null | head -100
jira board list --output json 2>/dev/null | head -100
jira me --output json 2>/dev/null
```

Also try:
```bash
jira sprint list --project {first-detected-project} --output json 2>/dev/null | head -50
jira issue list --project {first-detected-project} --sprint active --output json 2>/dev/null | head -50
```

Collect:
- List of project keys + names
- Board IDs and types (scrum/kanban)
- Active sprint name (if any)
- Current user's account info
- Sample issue types from recent issues

Form detected defaults. Hold them for the Q&A below.

---

## Step 2 — Ask key questions one section at a time

Use this format for each question:

```
[Section]

  Detected: <value>
  <brief explanation>

  → <question>
     Options: <opt1> | <opt2>  (or press Enter to accept)
```

Wait for the user's answer before moving to the next question.

---

### Q1 — Project

If multiple projects were found, list them:
```
Projects found in your Jira instance:
  1. PROJ — Mobile App
  2. SHARED — Shared Services
  3. INFRA — Infrastructure

→ Which project key does this team primarily work in?
   (Enter the key, e.g. PROJ)
```

If only one project was found, show it and ask for confirmation:
```
  Detected: PROJ — Mobile App

→ Is this the right project? [Y/n]
```

### Q2 — Board

```
  Detected: Mobile Board (ID: 42, type: scrum)

→ Is this the right board? [Y/n]
   (If you have multiple boards, enter the board ID from `jira board list`)
```

### Q3 — Board Type

```
  Detected: scrum

→ What type of board does your team use?
   Options: scrum | kanban
```

### Q4 — Issue Types

List the issue types found in the project:
```
  Detected issue types: Epic, Story, Task, Bug, Sub-task

→ Are all these correct for your team? [Y/n]
   (If you have custom types, list them: Epic, Story, Task, Bug, Spike, ...)
```

Then ask:
```
→ What type do you use for new feature work?
   Options: Story | Task | Feature  (default: Story)

→ What type do you use for bugs?
   Options: Bug | Defect  (default: Bug)

→ Do you use Spikes (research tasks)?
   Options: yes | no
```

### Q5 — Workflow Statuses

Run:
```bash
jira issue list --project {key} --output json 2>/dev/null | jq -r '.[].fields.status.name' | sort -u
```

Show detected statuses and ask:
```
  Detected workflow statuses: To Do, In Progress, In Review, QA, Done

→ Do these match your workflow? [Y/n]
   (If different, list your statuses in order: Backlog, Selected, In Dev, ...)
```

Then ask which status maps to each lifecycle stage:
```
→ Which status means "ready to start work"? (default: To Do)
→ Which status means "in active development"? (default: In Progress)
→ Which status means "PR is open / in review"? (default: In Review)
→ Which status means "merged, awaiting QA"? (leave blank if no QA stage)
→ Which status means "fully done"? (default: Done)
```

### Q6 — Sprint Setup

If active sprint found:
```
  Detected active sprint: "MOB Sprint 47" (started Mon 7 Apr)

→ Does this sprint name pattern look right?
   Pattern detected: "{project} Sprint {number}"
   Options: accept | enter your own pattern
```

Ask:
```
→ How long are your sprints?
   Options: 1-week | 2-weeks | 3-weeks | 4-weeks

→ What day do sprints start?
   Options: Monday | Tuesday | Wednesday | Thursday | Friday
```

### Q7 — Story Points

```
→ Does your team use story points?
   Options: yes | no

(If yes)
→ What Fibonacci scale does your team use?
   Options: 1,2,3,5,8,13,21 | 1,2,3,5,8,13 | t-shirt (XS,S,M,L,XL)
```

### Q8 — Linking Conventions

Show existing git-flow.config.md ticket-pattern if it exists:
```
  From git-flow.config.md: ticket-pattern = [A-Z]+-[0-9]+  (e.g. PROJ-123)

→ How should ticket IDs appear in branch names?
   Example: feature/PROJ-123-dark-mode
   Options: {KEY}-{ID} (default) | #{ID} | {ID}

→ How should tickets be referenced in commit messages?
   Example: feat(android): add dark mode PROJ-123
   Options: {KEY}-{ID} at end | #{ID} | footer "Refs: PROJ-123"
```

### Q9 — Labels & Components (optional)

```
→ Does your team use labels in Jira? (e.g. android, ios, tech-debt)
   If yes, list them (comma-separated), or press Enter to skip.

→ Does your project use Jira Components? (e.g. Android, iOS, API)
   If yes, list them, or press Enter to skip.
```

---

## Step 3 — Confirm before writing

Print a full summary:

```
## Summary — jira.config.md

  jira-url:              https://yourorg.atlassian.net
  project-key:           PROJ
  board-id:              42
  board-type:            scrum
  issue-types:           Epic, Story, Task, Bug, Sub-task, Spike
  default-issue-type:    Story
  default-bug-type:      Bug
  workflow-statuses:     To Do, In Progress, In Review, QA, Done
  status-in-progress:    In Progress
  status-in-review:      In Review
  status-done:           Done
  sprint-name-pattern:   PROJ Sprint {number}
  sprint-duration:       2-weeks
  sprint-start-day:      Monday
  story-points-scale:    1, 2, 3, 5, 8, 13, 21
  branch-ticket-format:  {KEY}-{ID}
  commit-ticket-format:  {KEY}-{ID}

Write jira.config.md with these values? [Y/n]
```

If the user says no, ask which values to change and loop back.

---

## Step 4 — Write jira.config.md

If `jira.config.md` already exists, ask:
```
jira.config.md already exists. Overwrite it? [y/N]
```

Write the file with all confirmed values. Add confidence indicators:
- `# ✓ confirmed by user`
- `# ✓ detected from Jira`
- `# ? inferred — please verify`

---

## Step 5 — Verify connection

After writing, run a live check:
```bash
jira issue list --project {key} --sprint active --no-headers 2>/dev/null | head -5
```

If it returns issues, show them as a quick preview:
```
## Live Check — Active Sprint Issues (first 5)

  PROJ-123  Story   Add dark mode support         Alice    In Progress  5pts
  PROJ-124  Bug     Crash on login with biometric  Bob     In Review    3pts
  ...

Your Jira integration is working.
```

If it fails, show a diagnostic:
```
Could not fetch active sprint issues. Possible reasons:
  • No active sprint (try /detect-jira again when a sprint is running)
  • Board ID may be wrong — check with: jira board list
  • Permissions issue — check your Jira role
```

---

## Step 6 — Report

Print:
```
## Jira Configuration Saved

jira.config.md written to project root.

Commit it so the whole team benefits:
  git add jira.config.md && git commit -m "chore: add jira.config.md"

Your jira-advisor agent can now:
  ✓ Show your current sprint board
  ✓ Create tickets with your project's issue types and workflow
  ✓ Transition issues through your workflow
  ✓ Break epics into stories
  ✓ Link branches and PRs to Jira tickets

Try it:
  "Show me the active sprint"
  "Create a story for adding biometric login to the Android app"
  "Move PROJ-123 to In Review"
  "Break down epic PROJ-100 into stories"
```
