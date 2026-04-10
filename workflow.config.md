# Claude Crew — Workflow Config
# Run /detect-workflow to auto-fill this file.
# Edit manually to override any value.

## Ticket System

ticket_system: jira          # jira | linear | github-issues | azure-devops | shortcut | asana | trello | notion | other
ticket_id_format: PROJ-123   # how tickets are referenced in commits/branches

# Jira (when ticket_system: jira)
jira_project_key: PROJ
jira_base_url: https://yourcompany.atlassian.net
jira_cli_available: false

# Linear (when ticket_system: linear)
# linear_team: engineering
# linear_git_integration: true

# GitHub Issues (when ticket_system: github-issues)
# github_repo: owner/repo
# github_projects: true

# Azure DevOps (when ticket_system: azure-devops)
# azure_org_url: https://dev.azure.com/org
# azure_project: MyProject

# Shortcut (when ticket_system: shortcut)
# shortcut_workspace: my-workspace

## Documentation

docs_platform: confluence    # confluence | notion | google-docs | markdown | gitbook | sharepoint | readme | obsidian | other

# Confluence (when docs_platform: confluence)
confluence_url: https://yourcompany.atlassian.net/wiki
confluence_space: ENG

# Notion (when docs_platform: notion)
# notion_workspace: My Workspace
# notion_prd_page: https://notion.so/...

# Markdown in repo (when docs_platform: markdown)
# docs_directory: docs/

## Communication

comms_tool: slack            # slack | teams | discord | email | other

# Slack
slack_engineering_channel: "#engineering"
slack_incidents_channel: "#incidents"

# Teams
# teams_team: Engineering
# teams_channel: General

## Process

sprint_length_weeks: 2       # 1 | 2 | 3 | 4 | kanban
