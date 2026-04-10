# Claude Crew — Product Config
# Run /detect-product-stack to auto-fill this file.
# All product agents read this before every task.

## Documentation & PRDs

# Where are PRDs, specs, and product docs written?
prd_tool: confluence            # confluence | notion | google-docs | markdown | productboard | aha | linear | other
prd_template_url:               # URL or path to your team's PRD template (optional)

# Confluence (when prd_tool: confluence)
confluence_url: https://yourcompany.atlassian.net/wiki
confluence_space: PROD
confluence_prd_parent_page: Product Requirements

# Notion (when prd_tool: notion)
# notion_workspace: My Workspace
# notion_prd_database_id: abc123

# Google Docs (when prd_tool: google-docs)
# gdrive_folder_id: abc123

# Markdown (when prd_tool: markdown)
# docs_directory: docs/product/

## Roadmapping

# Where is the product roadmap managed?
roadmap_tool: jira              # jira | linear | productboard | aha | miro | notion | spreadsheet | other
roadmap_time_horizon: quarterly # weekly | monthly | quarterly | annual

## User Stories & Tickets

# This inherits ticket_system from workflow.config.md
# Override if product uses a different system than engineering:
# ticket_system_override: none

# Story format preference
story_format: job-story         # user-story ("As a...") | job-story ("When...I want...so I can...") | both
acceptance_criteria_format: gherkin  # gherkin (Given/When/Then) | checklist | both

# Story point scale
estimation_scale: fibonacci     # fibonacci (1,2,3,5,8,13) | t-shirt (XS/S/M/L/XL) | none

## Metrics & Analytics

# What analytics platform does the product team use?
analytics_platform: amplitude   # amplitude | mixpanel | ga4 | segment | heap | posthog | custom | none

# Amplitude
# amplitude_project_id: abc123

# Mixpanel
# mixpanel_project_id: abc123

# Do you use a semantic layer or metrics store?
metrics_store: none             # looker | metabase | cube | custom | none

## Design

# Design tool
design_tool: figma              # figma | sketch | adobe-xd | penpot | other | none
design_system_url:              # URL to the design system or component library (optional)

# Do designs need sign-off before dev starts?
design_sign_off_required: true  # true | false

## Stakeholders

# Who reviews/approves PRDs?
prd_approvers: product-lead,engineering-lead,design-lead

# Exec update cadence
exec_update_cadence: weekly     # daily | weekly | monthly | ad-hoc

## Team Structure

# Team topology for context
team_model: stream-aligned      # stream-aligned | platform | enabling | complicated-subsystem
team_size_engineers: 8          # approximate number of engineers per team
squads:                         # comma-separated squad/team names (optional)

## Workflow Tools
# Set by /detect-workflow

ticket_system: jira             # from workflow.config.md
docs_platform: confluence       # from workflow.config.md
comms_tool: slack               # from workflow.config.md
sprint_length_weeks: 2          # from workflow.config.md
