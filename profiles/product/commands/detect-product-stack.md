---
description: Interactive setup for the product profile. Asks about PRD tool, roadmap tool, analytics platform, design tool, and workflow preferences. Writes product.config.md.
---

Run directly — do not spawn a sub-agent.

## Step 1 — Check prerequisites

Read `workflow.config.md`. If it doesn't exist, say:
```
⚠  workflow.config.md not found.
Run /detect-workflow first to set your ticket system and docs platform.
Continuing — you can run /detect-workflow afterwards.
```

Read `product.config.md` if it exists and ask to update if found.

---

## Step 2 — PRD and specifications tool

Ask:
```
Where does your team write PRDs, feature specs, and technical requirements?

  1) Confluence                  (Atlassian wiki)
  2) Notion                      (databases or pages)
  3) Google Docs / Google Drive
  4) Productboard
  5) Aha!
  6) Linear (with docs)
  7) Coda
  8) Markdown files in repo
  9) Microsoft Word / SharePoint
  10) Other

Enter number:
```

For choice 1 (Confluence):
```
  Confluence URL (e.g. https://company.atlassian.net/wiki):
  Space key for product docs (e.g. PROD, PM):
  PRD parent page title (e.g. "Product Requirements"):
```

For choice 2 (Notion):
```
  Notion workspace name:
  Is there a dedicated Notion database for PRDs? [y/N]
  If yes, database URL or ID:
```

For choice 3 (Google Docs):
```
  Google Drive folder for PRDs (name or URL):
  Do you use a standard PRD template doc? [y/N]
  If yes, template URL:
```

For choice 4 (Productboard):
```
  Productboard workspace URL:
  Do you link Productboard features to Jira/Linear? [y/N]
```

For choice 5 (Aha!):
```
  Aha! subdomain (e.g. yourcompany.aha.io):
  Do you push Aha! features to Jira/Linear? [y/N]
```

For choice 8 (Markdown):
```
  Path to product docs directory (e.g. docs/product/):
```

Ask:
```
Does your team use a standard PRD template? [y/N]
If yes, paste the URL or describe the key sections:
```

---

## Step 3 — Story writing format

Ask:
```
What format does your team use for user stories?

  1) User Story — "As a [user], I want [action] so that [benefit]"
  2) Job Story  — "When [situation], I want [motivation] so I can [outcome]"
  3) Both — depends on context
  4) Plain requirement statements

Enter number:
```

Ask:
```
What format do you use for acceptance criteria?

  1) Gherkin — Given / When / Then
  2) Numbered checklist
  3) Both
  4) Free text

Enter number:
```

Ask:
```
How does your team estimate story complexity?

  1) Fibonacci story points (1, 2, 3, 5, 8, 13, 21)
  2) T-shirt sizes (XS, S, M, L, XL)
  3) Hours
  4) No estimation (flow metrics only)

Enter number:
```

---

## Step 4 — Ticket / issue system (confirm for product)

Read `workflow.config.md` → `ticket_system`. Show:
```
Ticket system from workflow.config.md: <system>

Product agents will create stories and epics in <system>.
Is this correct? [Y/n]
```

If N, ask which system. Then ask for project/team details specific to that system.

If Jira:
```
  Jira project key for product epics/stories (may differ from engineering project):
  Epic issue type name (e.g. Epic, Initiative, Feature):
  Story issue type name (e.g. Story, User Story):
  Does your team use a backlog refinement workflow? [y/N]
```

If Linear:
```
  Linear team for product stories:
  Do you use Linear's roadmap view? [y/N]
```

If GitHub Issues:
```
  Labels used for epics (e.g. epic, initiative):
  Labels used for stories (e.g. story, feature):
```

---

## Step 5 — Roadmap tool

Ask:
```
Where is your product roadmap managed?

  1) Jira (roadmap view or Advanced Roadmaps)
  2) Linear (roadmap view)
  3) Productboard
  4) Aha!
  5) Miro / FigJam (visual board)
  6) Notion
  7) Google Sheets
  8) Same as PRD tool
  9) Other

Enter number:
```

Ask:
```
What time horizons does your roadmap cover?
  1) Weekly / sprint-level
  2) Monthly (rolling 3 months)
  3) Quarterly (Now / Next / Later)
  4) Annual (H1 / H2 or Q1-Q4)
  5) Multiple horizons (strategic + tactical)

Enter number:
```

---

## Step 6 — Analytics and metrics

Ask:
```
Which analytics platform does your team use to measure product outcomes?

  1) Amplitude
  2) Mixpanel
  3) Google Analytics 4 (GA4)
  4) Segment (+ downstream tools)
  5) Heap
  6) PostHog
  7) FullStory
  8) Custom / internal event system
  9) None

Enter number (or multiple separated by commas):
```

For Amplitude (choice 1):
```
  Amplitude project name or ID (optional, for context):
```

For Segment (choice 4):
```
  Segment source name:
  Downstream destinations (e.g. Amplitude, BigQuery):
```

Ask:
```
Does your team use a metrics store or semantic layer for standardised KPIs?
  1) Looker (LookML)
  2) dbt Metrics / MetricFlow
  3) Cube.js
  4) Custom SQL views
  5) None — each team defines their own

Enter number:
```

---

## Step 7 — Design tools

Ask:
```
Which design tool does your team use?

  1) Figma
  2) Sketch
  3) Adobe XD
  4) Penpot
  5) Whimsical
  6) Balsamiq (wireframes)
  7) None / design-less

Enter number:
```

Ask:
```
Is there an existing design system or component library? [y/N]
If yes, URL or name:
```

Ask:
```
Do designs require sign-off before development starts? [Y/n]
Who approves designs? (e.g. Design Lead, CPO, Stakeholder):
```

---

## Step 8 — Stakeholders and process

Ask:
```
Who typically reviews and approves PRDs before development starts?
(comma-separated roles, e.g. "Product Lead, Engineering Lead, Design Lead"):
```

Ask:
```
How often do you provide stakeholder / exec updates?
  1) Daily
  2) Weekly
  3) Monthly
  4) Per milestone / release
  5) Ad-hoc only

Enter number:
```

Ask:
```
How is the product team structured?
  1) Dedicated product team (PMs separate from squads)
  2) Embedded PMs (one PM per squad)
  3) Founder / founder-led product
  4) Mixed

Enter number:
```

---

## Step 9 — Write product.config.md

Write `product.config.md` with all gathered values.

---

## Step 10 — Confirm

```
✓ product.config.md written.

Product Stack:
  PRD tool        : <tool>
  Story format    : <format>
  Acceptance crit.: <format>
  Estimation      : <scale>
  Ticket system   : <system>
  Roadmap tool    : <tool>
  Analytics       : <platform>
  Design tool     : <tool>

Next steps:
  /prd <feature>              ← write a full PRD
  /user-story <epic>          ← break an epic into sprint stories
  /metrics-review <feature>   ← define KPIs and event schema
```
