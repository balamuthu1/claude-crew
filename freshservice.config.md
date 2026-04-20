# Freshservice Configuration

Run `/snap-triage` once this file is filled in.

---

## Connection

```
freshservice_domain: your-company.freshservice.com
freshservice_api_key_env: FRESHSERVICE_API_KEY
```

> The API key must be set as the environment variable named above.
> Never paste the key value here — use `export FRESHSERVICE_API_KEY=...` in your shell.

---

## Incident Filters

```
freshservice_filter_status: open,pending
freshservice_filter_tags:
freshservice_filter_category:
freshservice_filter_per_page: 30
```

- `freshservice_filter_status` — comma-separated Freshservice statuses to fetch (open=2, pending=3, resolved=4, closed=5)
- `freshservice_filter_tags` — optional tag names to narrow results (leave blank = all)
- `freshservice_filter_category` — optional category name (leave blank = all)
- `freshservice_filter_per_page` — max incidents per triage run (default 30)

---

## Escalation to Jira

```
jira_project_key: PROJ
jira_bug_type: Bug
jira_default_priority: High
```

- `jira_project_key` — Jira project where escalated bug tickets will be created
- `jira_bug_type` — Jira issue type to use (Bug / Defect — match your project's type names)
- `jira_default_priority` — default priority for escalated Jira bugs

---

## QA Triage Thresholds

```
escalate_severity: Critical,High
comment_only_severity: Medium,Low
```

- Incidents classified at `escalate_severity` levels will get a Jira Bug created automatically.
- Incidents at `comment_only_severity` levels get a triage comment only (no Jira ticket).

---

## Notes

Add any project-specific notes for the QA engineer here (known noise sources, categories to skip, etc.):

```
notes:
```
