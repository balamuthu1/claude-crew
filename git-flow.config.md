# Claude Crew — Git Flow Configuration
#
# Run /detect-gitflow to auto-populate this from your repo.
# Edit manually to correct anything the detector got wrong.
# Commit this file so the whole team benefits.

---

## Strategy

# Branching model: gitflow | github-flow | trunk-based | custom
strategy: gitflow

# Primary branches
main-branch: main              # production-ready, tagged releases
develop-branch: develop        # integration branch (gitflow only)

---

## Branch Naming

# Prefixes per branch type
feature-prefix: feature/
bugfix-prefix: bugfix/
hotfix-prefix: hotfix/
release-prefix: release/
chore-prefix: chore/
experiment-prefix: experiment/

# Ticket/issue ID format (regex). Leave empty if no ticket system.
# Examples: [A-Z]+-[0-9]+  (Jira: PROJ-123)
#           [0-9]+           (GitHub: 42)
ticket-pattern: "[A-Z]+-[0-9]+"

# Full branch name pattern. Tokens: {prefix} {ticket} {description}
# description is always lowercase-kebab-case
# Examples:
#   feature/PROJ-123-user-profile-screen
#   bugfix/PROJ-456-crash-on-login
branch-pattern: "{prefix}{ticket}-{description}"

# Set to false if your team doesn't use ticket IDs in branch names
require-ticket-in-branch: true

---

## Commit Conventions

# Style: conventional | angular | custom
# conventional → feat(scope): message
# angular      → same as conventional
# custom       → describe in custom-commit-format below
commit-style: conventional

# Allowed types for conventional/angular commits
commit-types: feat, fix, docs, style, refactor, perf, test, chore, ci, build, revert

# Allowed scopes (leave empty to allow any scope)
# Mobile-specific examples:
commit-scopes: android, ios, shared, api, db, ui, auth, nav, ci, release

# Breaking change marker: conventional uses ! suffix or BREAKING CHANGE footer
# feat(android)!: remove legacy login  ← breaking

# Custom format (only used when commit-style: custom)
# custom-commit-format: "[{ticket}] {type}: {message}"

---

## Versioning

# Scheme: semver | calver | custom
versioning: semver

# semver: MAJOR.MINOR.PATCH (e.g. 2.4.1)
# calver: YYYY.MM.PATCH     (e.g. 2025.04.1)

# Android: versionCode strategy (increment: always increment by 1)
android-version-code-strategy: increment

# iOS: CFBundleVersion strategy
ios-build-number-strategy: increment

# Where version is defined
# android-version-file: app/build.gradle.kts
# ios-version-file: MyApp/Info.plist  (or use agvtool)

---

## Sprint Workflow

# Sprint duration: 1-week | 2-weeks | 3-weeks | 4-weeks | custom
sprint-duration: 2-weeks

# Use sprint branches? (one branch per sprint, features branch from it)
use-sprint-branches: false

# If use-sprint-branches: true — pattern for sprint branch names
# Tokens: {YYYY} {MM} {WW} (ISO week number) {sprint-number}
# Examples: sprint/2025.04  sprint/47  sprint/2025-w14
sprint-branch-pattern: "sprint/{YYYY}.{WW}"

# Sprint branch base (what to branch sprint branch from)
sprint-branch-base: develop

# At sprint start, auto-sync these branches
sprint-start-sync: main, develop

---

## Pull Request Conventions

# PR title format. Tokens: {ticket} {type} {description}
# Examples:
#   PROJ-123: Add user profile screen
#   feat(android): add user profile screen
pr-title-format: "{ticket}: {description}"

# Base branch for feature PRs
pr-base-branch: develop

# Require ticket reference in PR title/body
require-ticket-in-pr: true

# Squash commits on merge? (keeps history clean)
merge-strategy: squash

---

## Protected Branches

# Branches that should never be pushed to directly
protected-branches: main, develop

# Require PR for these branches (no direct commits)
require-pr-for: main, develop

---

## Hotfix Workflow

# Where to branch a hotfix from
hotfix-base-branch: main

# After hotfix, merge back into (comma-separated)
hotfix-merge-into: main, develop

# Hotfix version bump: patch | minor
hotfix-version-bump: patch

---

## Release Workflow

# Where to branch a release from
release-base-branch: develop

# After release, merge back into (comma-separated)
release-merge-into: main, develop

# Tag format for releases. Token: {version}
release-tag-format: "v{version}"

# Create release notes from: git-log | changelog | both
release-notes-source: both

---

## Notes

# Free-form notes about your team's specific conventions,
# exceptions, or migration context.
# Agents will read this and never flag described patterns as violations.
# legacy-notes:
