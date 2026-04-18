# Agent Dispatch Tables & Protocols

## Subconscious Layer (always active — runs before every dispatch)

The subconscious is a silent background observer that primes every agent with session context.

**Session start:** `session-start.sh` automatically injects the previous session's WHISPER.md
into your context — no manual read needed. Spawn `subconscious-agent` once in background
at the start of the first dispatch so it builds a fresh whisper for this session.

**Before spawning ANY working agent (mid-session), do:**

1. **Check staleness** of `.claude/subconscious/WHISPER.md`:
   - Absent → stale. `event_count` − `whisper_event_count` ≥ 10 → stale.
2. **If stale**: spawn `subconscious-agent` with `run_in_background=true`. Do NOT wait for it.
3. **If WHISPER.md exists and was updated this session**: prepend up to 500 characters to the agent prompt:
   ```
   Subconscious context (background priming — not hard rules):
   [WHISPER.md content, truncated to 500 chars]
   ```

## Rules Injection for Spawned Agents

Before passing the prompt to any working agent, prepend the relevant sections from
`rules/RULES_DIGEST.md` under the heading `Active rules for this session (apply without exception):`.

| Agent prefix | Inject |
|---|---|
| `android-*`, `ios-*`, `mobile-*` | SHARED + MOBILE PROFILE |
| `api-*`, `backend-*`, `database-*`, `devops-*` | SHARED + BACKEND PROFILE |
| `test-*`, `automation-*`, `qa-*`, `bug-*`, `performance-tester` | SHARED + QA PROFILE |
| `frontend-*`, `ui-engineer`, `accessibility-auditor` | SHARED + FRONTEND PROFILE |
| `prd-*`, `user-story-*`, `product-*`, `metrics-*`, `stakeholder-*` | SHARED + PRODUCT PROFILE |
| `git-flow-advisor`, `jira-advisor`, `scrum-master`, `learning-agent` | SHARED only |
| `subconscious-agent` | No injection |

## Shared Agents (always active — all profiles)

| Trigger | Agent | Pass |
|---|---|---|
| branch name / commit message / PR title / sprint start / hotfix / release cut | `git-flow-advisor` | question + ticket/context |
| Jira ticket / sprint board / issue transition / epic breakdown / story points | `jira-advisor` | request + Jira ticket or feature description |
| sprint planning / standup / retro / sprint health / velocity / blockers / DoD / agile coaching | `scrum-master` | ceremony type + sprint context |
| /learn or teach Claude / /memory-review / extract session learnings | `learning-agent` | learning text or invoke mode |

## Mobile Profile Agents

| Trigger | Agent | Pass |
|---|---|---|
| build / implement Android feature | `android-developer` | feature description + relevant existing files |
| build / implement iOS feature | `ios-developer` | feature description + relevant existing files |
| review this Android / Kotlin code | `android-reviewer` | file paths |
| review this iOS / Swift code | `ios-reviewer` | file paths |
| mobile architecture / design the architecture | `mobile-architect` | feature description + platform |
| app is slow / ANR / jank / mobile performance | `mobile-performance` | file or symptom description |
| mobile security audit / pentest / OWASP mobile | `mobile-security` | files to audit |
| write mobile tests / test plan | `mobile-test-planner` | feature + implementation files |
| prepare release / release notes / Play Store / App Store | `release-manager` | version + changelog |
| accessibility audit / a11y / TalkBack / VoiceOver | `ui-accessibility` | UI file paths |

## Backend Profile Agents

| Trigger | Agent | Pass |
|---|---|---|
| build / implement API / backend feature | `api-developer` | feature description + backend.config.md |
| review this API / backend code | `api-reviewer` | file paths |
| backend architecture / design service | `backend-architect` | feature description |
| database / schema / migration / query | `database-specialist` | schema or query description |
| CI/CD / Docker / K8s / Terraform / deployment | `devops-advisor` | config files |
| backend security / OWASP API / secrets scan | `backend-security` | files to audit |
| write backend tests | `backend-test-planner` | feature + implementation files |

## QA Profile Agents

| Trigger | Agent | Pass |
|---|---|---|
| test strategy / test plan / coverage | `test-strategist` | feature or release scope |
| write automated tests / automation framework | `automation-engineer` | feature + stack context |
| load test / performance test / SLOs | `performance-tester` | target + expected load |
| triage bug / bug report / root cause | `bug-triager` | bug description + context |
| release sign-off / QA metrics / quality report | `qa-lead` | release version or feature |

## Product Profile Agents

| Trigger | Agent | Pass |
|---|---|---|
| write PRD / product requirements | `prd-author` | feature description |
| write user stories / break down epic | `user-story-writer` | epic or feature description |
| prioritise / roadmap / OKR / RICE | `product-manager` | feature list or context |
| define metrics / KPIs / analytics events | `metrics-analyst` | feature or area |
| stakeholder update / exec summary / demo prep | `stakeholder-advisor` | context and audience |

## Frontend Profile Agents

| Trigger | Agent | Pass |
|---|---|---|
| build / implement UI feature / component | `frontend-developer` | feature description + frontend.config.md |
| review this frontend / React / Vue code | `frontend-reviewer` | file paths |
| design system / CSS / UI components | `ui-engineer` | component description |
| web accessibility / WCAG / ARIA | `accessibility-auditor` | UI file paths |
| frontend architecture / state management / bundle | `frontend-architect` | architecture question |
