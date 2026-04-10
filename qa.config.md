# Claude Crew — QA Config
# Run /detect-qa-stack to auto-fill this file.
# All QA agents read this before every task.

## Test Stack

# Unit / integration test frameworks (detected from project)
unit_test_framework: jest       # jest | pytest | junit | rspec | go-test | mocha | vitest

# E2E / UI test framework
e2e_framework: cypress          # cypress | playwright | selenium | webdriverio | none

# Mobile UI test framework
mobile_test_framework: none     # appium | espresso | xcuitest | detox | none

# API test framework
api_test_framework: supertest   # supertest | rest-assured | pytest-requests | postman | none

# Performance / load test framework
perf_test_framework: k6         # k6 | jmeter | gatling | locust | artillery | none

# Test runner command
test_run_command: npm test

## Environments

environments: dev,staging,prod  # comma-separated list of environment names
staging_url: https://staging.example.com
prod_url: https://app.example.com

## Test Management

# Where are test cases documented/tracked?
test_management: jira           # jira | linear | testrail | zephyr | xray | notion | spreadsheet | none

# TestRail (when test_management: testrail)
# testrail_url: https://yourcompany.testrail.io
# testrail_project_id: 1

# Xray (when test_management: xray)
# xray_project_key: PROJ

## Bug Tracking

# Inherits ticket_system from workflow.config.md
# Override here if QA uses a separate bug tracker:
# bug_tracker: jira

# Severity labels used in your bug tracker
severity_labels: critical,high,medium,low

## CI/CD Integration

ci_test_stage: test             # name of the CI stage that runs tests
test_report_format: junit-xml   # junit-xml | allure | html | cucumber | none
fail_on_flaky: false            # true | false

## Coverage

unit_coverage_target: 80        # % minimum for unit tests
require_coverage_gate: true     # fail CI if below target

## QA Process

qa_approach: shift-left         # shift-left | traditional | mixed
qa_in_sprint: true              # are QA engineers part of the feature sprint?
definition_of_done: |           # what must be true for a story to be "done"
  - Unit tests written and passing
  - Integration tests updated
  - Acceptance criteria tested
  - No open Critical/High bugs
  - Performance within SLO

## Workflow Tools
# Set by /detect-workflow

ticket_system: jira             # from workflow.config.md
docs_platform: confluence       # from workflow.config.md
