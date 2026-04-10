---
description: Interactive setup for the QA profile. Detects test frameworks, asks about environments, test management, and workflow tool preferences. Writes qa.config.md.
---

Run directly — do not spawn a sub-agent.

## Step 1 — Check prerequisites

Read `workflow.config.md`. If it doesn't exist, say:
```
⚠  workflow.config.md not found.
Run /detect-workflow first to set your ticket system and docs platform.
Continuing with detection — you can run /detect-workflow afterwards.
```

Read `qa.config.md` if it exists and ask to update if found.

---

## Step 2 — Auto-detect test frameworks

Scan for test-related dependencies in:
- `package.json` → look for cypress, playwright, jest, vitest, mocha, supertest, k6, artillery
- `requirements.txt` / `pyproject.toml` → look for pytest, selenium, locust, httpx
- `build.gradle` / `pom.xml` → look for junit, testng, gatling, rest-assured
- `Gemfile` → look for rspec, capybara, cucumber

Show what was detected:
```
Detected test frameworks:
  Unit/Integration : Jest
  E2E              : Playwright (found in devDependencies)
  Performance      : none detected
```

Ask: "Is this correct? [Y/n]"

---

## Step 3 — Test framework confirmation

For any framework type NOT auto-detected, ask:

```
E2E / UI test framework:
  1) Cypress
  2) Playwright
  3) Selenium / WebDriver
  4) WebdriverIO
  5) Puppeteer
  6) None (manual only)

Enter number:
```

```
API test framework:
  1) Supertest (Node.js)
  2) REST Assured (Java)
  3) pytest + httpx / requests (Python)
  4) Postman / Newman (CLI)
  5) Insomnia
  6) None — covered by integration tests

Enter number:
```

```
Performance / load test framework:
  1) k6
  2) JMeter
  3) Gatling
  4) Locust
  5) Artillery
  6) None

Enter number:
```

For mobile projects:
```
Mobile UI test framework:
  1) Appium
  2) Espresso (Android only)
  3) XCUITest (iOS only)
  4) Detox
  5) None

Enter number:
```

---

## Step 4 — Environments

Ask:
```
What environments does your team test against?
List them separated by commas (e.g. dev,staging,prod or dev,qa,uat,prod):
```

Ask:
```
What is the URL of your staging/QA environment?
(Used for automated test targeting and smoke tests)
Staging URL:
```

Ask:
```
Does your team have a dedicated QA environment separate from dev? [y/N]
```

---

## Step 5 — Test case management

Ask:
```
Where are your test cases documented and tracked?

  1) Jira (with Zephyr or Xray plugin)
  2) TestRail
  3) Xray (standalone)
  4) Zephyr Scale (TM4J)
  5) Confluence pages / tables
  6) Notion database
  7) Google Sheets / Docs
  8) GitHub Issues / Projects
  9) Linear
  10) Not tracked — tests live only in code
  11) Other

Enter number:
```

For TestRail (choice 2):
```
  TestRail URL:
  TestRail Project ID:
```

For Jira + Xray (choice 1 or 3):
```
  Xray test case issue type (e.g. Test, Test Case):
  Xray test execution issue type (e.g. Test Execution):
```

---

## Step 6 — Bug tracking preference

Read `workflow.config.md` → `ticket_system`. Show:
```
Bug tracker from workflow.config.md: <system>

QA agents will log bugs in <system>.
Does your QA team use the same system? [Y/n]
```

If N:
```
Which system does QA use for bugs?
  1) Jira
  2) Linear
  3) GitHub Issues
  4) Azure DevOps Boards
  5) Shortcut
  6) Trello
  7) Other

Enter number:
```

Ask:
```
What severity labels does your bug tracker use?
(Press Enter to use default: critical,high,medium,low)
Your labels (comma-separated):
```

---

## Step 7 — QA process

Ask:
```
How is QA integrated into your development process?

  1) Shift-left — QA engineers embed in feature squads, test during development
  2) Traditional — QA team receives builds after dev is complete
  3) Mixed — shift-left for new features, dedicated QA phase for releases

Enter number:
```

Ask:
```
Are QA engineers part of the sprint team (attend planning, stand-ups, retros)? [y/N]
```

Ask:
```
What is your sprint/iteration length?
(Press Enter to use value from workflow.config.md: <value>)
```

Ask:
```
What is your team's Definition of Done for a story to pass QA?
(Press Enter to use default, or type your custom DoD):
Default:
  - Acceptance criteria tested
  - Unit tests passing
  - No open Critical or High bugs
  - Performance within SLO
  - Accessibility checked (if UI)
```

---

## Step 8 — CI test integration

Ask:
```
What format do your test results use in CI?
  1) JUnit XML (most common — works with GitHub Actions, Jenkins, GitLab)
  2) Allure Report
  3) HTML Report
  4) Cucumber / BDD JSON
  5) Custom

Enter number:
```

Ask:
```
Should CI fail if unit test coverage drops below the target? [Y/n]
Coverage target % (default 80):
```

---

## Step 9 — Workflow preferences

Read `workflow.config.md`. Confirm or override ticket/docs settings for QA context.

---

## Step 10 — Write qa.config.md

Write `qa.config.md` with all gathered values.

---

## Step 11 — Confirm

```
✓ qa.config.md written.

QA Stack:
  E2E             : <framework>
  Performance     : <framework>
  Test Management : <tool>
  Bug Tracker     : <system>
  Environments    : <list>
  QA Process      : <shift-left|traditional|mixed>

Next steps:
  /test-plan <feature>          ← generate a risk-based test plan
  /regression-suite <feature>   ← write automated regression tests
  /qa-review <version>          ← release sign-off checklist
```
