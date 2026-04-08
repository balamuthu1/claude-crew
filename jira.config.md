# Claude Crew — Jira Configuration
#
# Run /detect-jira to auto-populate this from your Jira instance.
# Edit manually to correct anything the detector got wrong.
# Commit this file so the whole team benefits.
#
# Requires: Jira CLI (https://github.com/ankitpokhrel/jira-cli)
#   Install: brew install ankitpokhrel/jira-cli/jira-cli
#   Setup:   jira init

---

## Connection

# Your Jira instance base URL (no trailing slash)
jira-url: https://yourorg.atlassian.net

# Jira CLI profile name (from `jira me` / ~/.config/.jira/.config.yml)
jira-profile: default

---

## Project

# Primary project key (e.g. PROJ, MOB, AND)
project-key: PROJ

# Additional project keys this team works in (comma-separated)
# secondary-projects: SHARED, INFRA

# Board ID (find with: jira board list --project PROJ)
board-id: 1

# Board type: scrum | kanban
board-type: scrum

---

## Issue Types

# Issue types used by this team (as they appear in Jira)
issue-types: Epic, Story, Task, Bug, Sub-task, Spike

# Default type when creating a new feature issue
default-issue-type: Story

# Default type when reporting a bug
default-bug-type: Bug

# Type used for technical/chore work
default-chore-type: Task

# Type used for spikes / research
default-spike-type: Spike

---

## Workflow Statuses

# All statuses in order (comma-separated, exactly as they appear in Jira)
workflow-statuses: To Do, In Progress, In Review, QA, Done

# Status meaning "ready to start" (backlog refined, no blockers)
status-ready: To Do

# Status meaning "actively being developed"
status-in-progress: In Progress

# Status meaning "PR open, awaiting review"
status-in-review: In Review

# Status meaning "merged, awaiting QA sign-off"
status-in-qa: QA

# Status meaning "fully done"
status-done: Done

# Status to transition to when starting work on a ticket
start-transition: In Progress

# Status to transition to when opening a PR
pr-transition: In Review

---

## Sprint

# Sprint naming convention
# Tokens: {project} {number} {YYYY} {MM} {DD}
# Examples: "MOB Sprint 47"  "Q2 Sprint 3"  "2025.04 Sprint 1"
sprint-name-pattern: "{project} Sprint {number}"

# Sprint duration: 1-week | 2-weeks | 3-weeks | 4-weeks
sprint-duration: 2-weeks

# Sprint start day: Monday | Tuesday | Wednesday | Thursday | Friday
sprint-start-day: Monday

# Velocity (story points per sprint, used for planning estimates)
# sprint-velocity: 40

---

## Story Points

# Field name used for story points in your Jira instance
# Common values: story_points | story-points | customfield_10016
story-points-field: story_points

# Fibonacci scale used by team
story-points-scale: 1, 2, 3, 5, 8, 13, 21

---

## Epics

# How epics are linked to stories in your Jira version
# epic-link | parent (next-gen / team-managed projects use parent)
epic-link-field: parent

---

## Labels & Components

# Standard labels your team uses (comma-separated)
# labels: android, ios, backend, infrastructure, tech-debt

# Components defined in your project (comma-separated)
# components: Android, iOS, API, CI/CD

---

## Linking Conventions

# How Jira ticket IDs appear in branch names (matches git-flow.config.md)
# Tokens: {key} = project key (PROJ), {id} = numeric ID (123)
branch-ticket-format: "{key}-{id}"

# How Jira tickets are referenced in commit messages
# Examples: PROJ-123  #123  [PROJ-123]
commit-ticket-format: "{key}-{id}"

# How Jira tickets are referenced in PR titles
pr-ticket-format: "{key}-{id}"

---

## Notes

# Free-form notes about your Jira setup, field customisations,
# or workflow exceptions.
# Agents will read this and adapt accordingly.
# notes:
