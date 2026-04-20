---
description: Reference guide for Freshservice incident triage. Covers API auth, incident fetching, comment posting, escalation criteria, and codebase investigation integration. Used by the freshservice-analyst agent and the /snap-triage command.
user-invocable: false
---

# Freshservice Triage — Reference Guide

The QA engineer runs `/snap-triage` each morning to process open Freshservice incidents. This skill covers every pattern the `freshservice-analyst` agent needs.

---

## Pre-Flight Checklist

Before any API call:

```bash
# 1. Verify config file exists
[ -f freshservice.config.md ] || { echo "ERROR: freshservice.config.md not found. Fill in the template."; exit 1; }

# 2. Read domain and API key env var name from config
DOMAIN=$(grep -oP '(?<=freshservice_domain:\s)\S+' freshservice.config.md)
API_KEY_VAR=$(grep -oP '(?<=freshservice_api_key_env:\s)\S+' freshservice.config.md)

[ -z "$DOMAIN" ] && { echo "ERROR: freshservice_domain not set in freshservice.config.md"; exit 1; }
[ -z "$API_KEY_VAR" ] && { echo "ERROR: freshservice_api_key_env not set in freshservice.config.md"; exit 1; }

# 3. Check env var is exported
API_KEY="${!API_KEY_VAR}"
[ -z "$API_KEY" ] && { echo "ERROR: $API_KEY_VAR is not set. Run: export $API_KEY_VAR=<your_key>"; exit 1; }

# 4. Build auth header (never log $API_KEY)
AUTH=$(printf '%s:X' "$API_KEY" | base64 -w 0)
echo "Pre-flight OK. Domain: $DOMAIN"
```

---

## Fetching Incidents

```bash
# Map status names to Freshservice numeric codes
map_status() {
  case "$1" in
    open)     echo 2 ;;
    pending)  echo 3 ;;
    resolved) echo 4 ;;
    closed)   echo 5 ;;
    *)        echo "$1" ;;
  esac
}

STATUS_CODES=$(grep -oP '(?<=freshservice_filter_status:\s)\S+' freshservice.config.md \
  | tr ',' '\n' | while read s; do map_status "$s"; done | paste -sd,)

PER_PAGE=$(grep -oP '(?<=freshservice_filter_per_page:\s)\d+' freshservice.config.md 2>/dev/null || echo 30)

RESPONSE=$(curl -s -w "\n%{http_code}" \
  -H "Authorization: Basic $AUTH" \
  -H "Content-Type: application/json" \
  "https://${DOMAIN}/api/v2/tickets?status=${STATUS_CODES}&per_page=${PER_PAGE}&order_by=created_at&order_type=desc")

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | sed '$d')

[ "$HTTP_CODE" != "200" ] && { echo "ERROR: Freshservice returned $HTTP_CODE"; echo "$BODY"; exit 1; }
echo "$BODY"
```

---

## Adding a Triage Note

```bash
# $TICKET_ID — Freshservice numeric ticket ID
# $COMMENT   — plain text comment body (no raw JSON)

ESCAPED=$(printf '%s' "$COMMENT" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read()))")

RESULT=$(curl -s -w "\n%{http_code}" -X POST \
  -H "Authorization: Basic $AUTH" \
  -H "Content-Type: application/json" \
  "https://${DOMAIN}/api/v2/tickets/${TICKET_ID}/notes" \
  -d "{\"body\": ${ESCAPED}, \"private\": false}")

HTTP_CODE=$(echo "$RESULT" | tail -1)
[ "$HTTP_CODE" != "201" ] && echo "WARN: Note post returned $HTTP_CODE for ticket #$TICKET_ID"
```

---

## Rate Limit Handling

Freshservice enforces per-minute limits. On HTTP 429:

```bash
retry_with_backoff() {
  local cmd="$1"
  local attempt=0
  local wait=10
  while [ $attempt -lt 3 ]; do
    OUTPUT=$(eval "$cmd")
    CODE=$(echo "$OUTPUT" | tail -1)
    [ "$CODE" != "429" ] && { echo "$OUTPUT"; return 0; }
    echo "Rate limited. Waiting ${wait}s..." >&2
    sleep $wait
    wait=$((wait * 2))
    attempt=$((attempt + 1))
  done
  echo "ERROR: Freshservice rate limit persists after 3 retries." >&2
  return 1
}
```

---

## Escalation Criteria

Read thresholds from `freshservice.config.md`:

| Decision | When |
|----------|------|
| **ESCALATE** | Severity in `escalate_severity` list AND incident describes a reproducible product defect |
| **COMMENT** | Severity in `comment_only_severity` list, OR issue is environmental / infra / user error |
| **SKIP** | Duplicate, spam, test ticket, out of engineering scope |

---

## Triage Comment Template

```
[QA Triage — {{DATE}}]
Decision: {{ESCALATE|COMMENT|SKIP}}
Severity: {{Critical|High|Medium|Low}}
Jira: {{PROJ-NNN or N/A}}

Analysis:
{{2–3 sentences: what the incident describes, why this severity, next steps}}

Fix Plan:
{{Summary of codebase investigation: candidate files, root cause hypothesis, suggested change.
  OR: "Root cause not identified in codebase scan — further investigation required."}}
```

---

## Codebase Investigation Checklist

When `bug-triager` investigates an ESCALATE incident:

1. Extract the error message, feature name, or component from the Freshservice ticket description
2. `Grep` for the exact error string or relevant function/component name
3. `Glob` for files in the suspected component directory
4. `Read` the candidate files; identify the code path that could produce the reported behaviour
5. Form a hypothesis: "This is likely caused by X in `path/to/file.ts:42` because Y"
6. Rate confidence: **High** (strong match) / **Medium** (plausible) / **Low** (speculation)
7. If nothing found after 3 search attempts: return `NO_FIX_FOUND`

---

## Security Rules

- API key comes exclusively from the env var declared in `freshservice.config.md`
- Never print, log, or embed the API key in any file or comment
- Never include PII from incident tickets in Jira ticket descriptions unless the data is already public
- Never post private internal notes as public Freshservice comments — always set `"private": false` intentionally
