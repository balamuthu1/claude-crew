---
description: JIRA CLI integration for any JIRA project. Resolves the project key from product.config.md at runtime. Provides authenticated jira-cli commands for creating, reading, updating, and querying tickets. Used by prd-author, user-story-writer, metrics-analyst, and stakeholder-advisor agents to push work directly to JIRA without manual copy-paste.
allowed-tools: Bash
user-invocable: false
---

# JIRA CLI Integration

This skill enables product agents to create and manage JIRA tickets directly using
`jira` CLI (ankitpokhrel/jira-cli). Agents MUST use these patterns instead of
printing "Create ticket: ..." instructions.

The project key is resolved at runtime from `product.config.md`. No project key
is hardcoded — this skill works for any JIRA instance.

---

## Pre-Flight Check (run ONCE at the start of any ticket-creation stage)

```bash
# Step 1 — Verify CLI is installed
if ! command -v jira &> /dev/null; then
  echo "ERROR: jira CLI not installed."
  echo "Install: brew install ankitpokhrel/jira-cli/jira-cli"
  echo "Then:    jira init"
  exit 1
fi

# Step 2 — Verify authentication
jira me --plain 2>/dev/null || {
  echo "ERROR: jira CLI not authenticated. Run: jira init"
  exit 1
}

# Step 3 — Resolve project key (checked in order)
PROJECT=""

# 3a. Read from product.config.md
if [ -f "product.config.md" ]; then
  PROJECT=$(grep -oP '(?<=jira_project_key:\s)\S+' product.config.md 2>/dev/null | head -1)
fi

# 3b. Try workflow.config.md as fallback
if [ -z "$PROJECT" ] && [ -f "workflow.config.md" ]; then
  PROJECT=$(grep -oP '(?<=jira_project_key:\s)\S+' workflow.config.md 2>/dev/null | head -1)
fi

# 3c. Auto-detect: use the first project the CLI can see
if [ -z "$PROJECT" ]; then
  PROJECT=$(jira project list --plain 2>/dev/null | awk 'NR==2{print $1}')
fi

if [ -z "$PROJECT" ]; then
  echo "ERROR: JIRA project key not found."
  echo "Fix: add 'jira_project_key: YOUR_KEY' to product.config.md"
  echo "     or run /detect-product-stack to configure."
  exit 1
fi

echo "jira CLI ready. Project: $PROJECT"
# All commands below use $PROJECT — do NOT hardcode a project key
```

If the pre-flight fails, fall back to printing formatted ticket templates the user can paste manually.

---

## Project Configuration

The project key (`$PROJECT`) is resolved from `product.config.md → jira_project_key`.
All other settings come from the JIRA project itself — no configuration needed here.

| Setting | Source |
|---|---|
| Project key | `product.config.md → jira_project_key` (auto-detected if missing) |
| Issue types | Configured in your JIRA project (Story, Task, Bug, Spike, Epic) |
| Priority values | Highest, High, Medium, Low |
| Labels | Team/feature labels — pass as `--label` arguments |

---

## Create Tickets

### Story
```bash
TICKET=$(jira issue create \
  --project "$PROJECT" \
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
  --label [feature-label] \
  --no-input --plain 2>&1)

echo "$TICKET"
KEY=$(echo "$TICKET" | grep -oP '[A-Z]+-\d+')
echo "Created story: $KEY"
```

### Task
```bash
TICKET=$(jira issue create \
  --project "$PROJECT" \
  --type Task \
  --summary "[summary]" \
  --body "[description with AC]" \
  --priority Medium \
  --no-input --plain 2>&1)

KEY=$(echo "$TICKET" | grep -oP '[A-Z]+-\d+')
echo "Created task: $KEY"
```

### Epic
```bash
EPIC=$(jira epic create \
  --project "$PROJECT" \
  --name "[Epic name]" \
  --summary "[Epic one-liner]" \
  --body "[Overview, scope, PRD reference]" \
  --no-input --plain 2>&1)

EPIC_KEY=$(echo "$EPIC" | grep -oP '[A-Z]+-\d+')
echo "Created epic: $EPIC_KEY"
```

### Bug
```bash
jira issue create \
  --project "$PROJECT" \
  --type Bug \
  --summary "Fix: [summary]" \
  --body "[steps to reproduce, expected, actual, stack trace placeholder]" \
  --priority Highest \
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
jira issue view "$PROJECT-123" --plain

# List open tickets in current sprint
jira sprint list --current --plain

# JQL search
jira issue list --jql "project = $PROJECT AND labels = \"feature-label\" AND status != Done" --plain

# Find epic's child tickets
jira issue list --jql "project = $PROJECT AND \"Epic Link\" = $EPIC_KEY" --plain
```

---

## Update

```bash
# Transition status
jira issue move "$PROJECT-123" "In Progress"

# Add comment
jira issue comment add "$PROJECT-123" "Implementation approved."

# Edit priority
jira issue edit "$PROJECT-123" --priority High --no-input
```

---

## Error Handling Pattern

Always capture output and check for any ticket key (pattern `[A-Z]+-\d+`):

```bash
result=$(jira issue create ... --no-input --plain 2>&1)
if echo "$result" | grep -qP '[A-Z]+-\d+'; then
  KEY=$(echo "$result" | grep -oP '[A-Z]+-\d+')
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
KEYS[data]=$(jira issue create --project "$PROJECT" --type Task \
  --summary "[data layer task]" --body "..." \
  --priority Medium --no-input --plain 2>&1 \
  | grep -oP '[A-Z]+-\d+')

KEYS[repo]=$(jira issue create --project "$PROJECT" --type Task \
  --summary "[repository task]" --body "..." \
  --priority Medium --no-input --plain 2>&1 \
  | grep -oP '[A-Z]+-\d+')

KEYS[ui]=$(jira issue create --project "$PROJECT" --type Story \
  --summary "[UI story]" --body "..." \
  --priority High --no-input --plain 2>&1 \
  | grep -oP '[A-Z]+-\d+')

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
