---
description: JIRA CLI integration for the MOBNEW project. Provides authenticated jira-cli commands for creating, reading, updating, and querying tickets. Used by prd-author, user-story-writer, metrics-analyst, and stakeholder-advisor agents to push work directly to JIRA without manual copy-paste.
allowed-tools: Bash
user-invocable: false
---

# JIRA CLI Integration — MOBNEW Project

This skill enables product agents to create and manage JIRA tickets directly using
`jira` CLI (ankitpokhrel/jira-cli). Agents MUST use these patterns instead of
printing "Create ticket: ..." instructions.

---

## Pre-Flight Check (run ONCE at the start of any ticket-creation stage)

```bash
# Verify CLI installed and authenticated before creating any ticket
if ! command -v jira &> /dev/null; then
  echo "ERROR: jira CLI not installed."
  echo "Install: brew install ankitpokhrel/jira-cli/jira-cli"
  echo "Then:    jira init"
  exit 1
fi
jira me --plain 2>/dev/null || {
  echo "ERROR: jira CLI not authenticated. Run: jira init"
  exit 1
}
echo "jira CLI ready."
```

If the pre-flight fails, fall back to printing formatted ticket templates the user can paste manually.

---

## MOBNEW Project Configuration

| Setting | Value |
|---|---|
| Project key | `MOBNEW` |
| Issue types | Story, Task, Bug, Spike, Epic |
| Priority values | Highest (P0), High (P1), Medium (P2), Low (P3) |
| Labels | `android`, `gbt-mobile`, `neo-mobile` + feature label |
| Components | Module path: `feature/tripDetail`, `core/network`, etc. |

---

## Create Tickets

### Story
```bash
TICKET=$(jira issue create \
  --project MOBNEW \
  --type Story \
  --summary "[summary]" \
  --body "$(cat <<'BODY'
## Description
[description]

## Acceptance Criteria
- [ ] AC-1: [criterion]
- [ ] AC-2: [criterion]

## Edge Cases
- [ ] EC-1: [scenario]

## Out of scope
[scope guard]
BODY
)" \
  --priority [High|Medium|Low|Highest] \
  --label android \
  --label [feature-label] \
  --no-input --plain 2>&1)

echo "$TICKET"
KEY=$(echo "$TICKET" | grep -oP 'MOBNEW-\d+')
echo "Created story: $KEY"
```

### Task
```bash
TICKET=$(jira issue create \
  --project MOBNEW \
  --type Task \
  --summary "[summary]" \
  --body "[description with AC]" \
  --priority Medium \
  --label android \
  --no-input --plain 2>&1)

KEY=$(echo "$TICKET" | grep -oP 'MOBNEW-\d+')
echo "Created task: $KEY"
```

### Epic
```bash
EPIC=$(jira epic create \
  --project MOBNEW \
  --name "[Epic name]" \
  --summary "[Epic one-liner]" \
  --body "[Overview, scope, PRD reference]" \
  --no-input --plain 2>&1)

EPIC_KEY=$(echo "$EPIC" | grep -oP 'MOBNEW-\d+')
echo "Created epic: $EPIC_KEY"
```

### Bug
```bash
jira issue create \
  --project MOBNEW \
  --type Bug \
  --summary "Fix: [summary]" \
  --body "[steps to reproduce, expected, actual, stack trace placeholder]" \
  --priority Highest \
  --label android \
  --label bug-fix \
  --no-input
```

---

## Link, Assign to Epic, and Add to Sprint

```bash
# Link dependency (A is blocked by B)
jira issue link "$KEY_A" "$KEY_B" "is blocked by"

# Add tickets to an epic
jira epic add "$EPIC_KEY" "$KEY_1" "$KEY_2" "$KEY_3"

# Add to current sprint
SPRINT_ID=$(jira sprint list --current --plain | awk 'NR==2{print $1}')
jira sprint add "$SPRINT_ID" "$KEY"
```

---

## Read / Query

```bash
# View a specific ticket
jira issue view MOBNEW-850 --plain

# List open tickets in current sprint
jira sprint list --current --plain

# JQL search
jira issue list --jql 'project = MOBNEW AND labels = "feature-label" AND status != Done' --plain

# Find epic's child tickets
jira issue list --jql 'project = MOBNEW AND "Epic Link" = MOBNEW-800' --plain
```

---

## Update

```bash
# Transition status
jira issue move MOBNEW-850 "In Progress"

# Add comment
jira issue comment add MOBNEW-850 "Implementation approved."

# Edit priority
jira issue edit MOBNEW-850 --priority High --no-input
```

---

## Error Handling Pattern

Always capture output and check for the ticket key:

```bash
result=$(jira issue create ... --no-input --plain 2>&1)
if echo "$result" | grep -qP 'MOBNEW-\d+'; then
  KEY=$(echo "$result" | grep -oP 'MOBNEW-\d+')
  echo "SUCCESS: $KEY"
else
  echo "WARN: JIRA create failed. Falling back to template output."
  echo "$result"
  # Print a formatted ticket template the user can paste manually
fi
```

---

## Batch Creation Pattern

When creating a full story set from a PRD, capture keys and link dependencies:

```bash
declare -A KEYS

# Create in dependency order (foundational first)
KEYS[data]=$(jira issue create --project MOBNEW --type Task \
  --summary "[data layer task]" --body "..." \
  --priority Medium --label android --no-input --plain 2>&1 \
  | grep -oP 'MOBNEW-\d+')

KEYS[repo]=$(jira issue create --project MOBNEW --type Task \
  --summary "[repository task]" --body "..." \
  --priority Medium --label android --no-input --plain 2>&1 \
  | grep -oP 'MOBNEW-\d+')

KEYS[ui]=$(jira issue create --project MOBNEW --type Story \
  --summary "[UI story]" --body "..." \
  --priority High --label android --no-input --plain 2>&1 \
  | grep -oP 'MOBNEW-\d+')

# Link dependencies
jira issue link "${KEYS[repo]}" "${KEYS[data]}" "is blocked by"
jira issue link "${KEYS[ui]}" "${KEYS[repo]}" "is blocked by"

# Add all to epic
jira epic add "$EPIC_KEY" "${KEYS[data]}" "${KEYS[repo]}" "${KEYS[ui]}"

# Print summary
echo "Tickets created:"
for name in "${!KEYS[@]}"; do
  echo "  $name → ${KEYS[$name]}"
done
```
