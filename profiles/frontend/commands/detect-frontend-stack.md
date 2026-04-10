---
description: Interactive setup for the frontend profile. Auto-detects framework, build tool, styling, and state management from package.json, then asks about design tools and workflow preferences. Writes frontend.config.md.
---

Run directly — do not spawn a sub-agent.

## Step 1 — Check prerequisites

Read `workflow.config.md`. If it doesn't exist, say:
```
⚠  workflow.config.md not found.
Run /detect-workflow first to set your ticket system and docs platform.
Continuing — you can run /detect-workflow afterwards.
```

Read `frontend.config.md` if it exists and ask to update if found.

---

## Step 2 — Auto-detect from project files

Read the following files to detect the stack:
- `package.json` — framework, build tool, test framework, state management, styling
- `tsconfig.json` — TypeScript strictness (`strict: true`, `noUncheckedIndexedAccess`, etc.)
- `vite.config.*` / `next.config.*` / `nuxt.config.*` / `angular.json` — meta-framework and build
- `tailwind.config.*` — Tailwind CSS confirmation
- `.eslintrc*` / `eslint.config.*` — linting rules
- `.prettierrc*` — formatter

Detect:
- Framework (react, vue, angular, svelte, solid)
- Meta-framework (next, nuxt, remix, sveltekit, astro, none)
- Language (typescript / javascript + strictness level)
- Build tool (vite, webpack, turbopack, esbuild)
- State management (redux, zustand, pinia, ngrx, jotai, context)
- Server state (react-query, swr, apollo, urql)
- Styling (tailwind, css-modules, styled-components, emotion, sass)
- Component library (from package.json dependencies)
- Test frameworks (jest, vitest, cypress, playwright)

Show detected values:
```
Detected:
  Framework       : React 18 + Next.js 14 (App Router)
  Language        : TypeScript (strict mode)
  Build tool      : Turbopack
  State           : Zustand + React Query
  Styling         : Tailwind CSS + shadcn/ui
  Tests           : Vitest (unit) + Playwright (E2E)
  Linting         : ESLint + Prettier
```

Ask: "Is this correct? [Y/n]"

Allow the user to correct any values before continuing.

---

## Step 3 — Framework clarification (if needed)

If framework could not be determined, ask:
```
Which frontend framework does this project use?

  1) React (library)
  2) Next.js (React meta-framework)
  3) Remix (React meta-framework)
  4) Vue 3
  5) Nuxt 3 (Vue meta-framework)
  6) Angular
  7) Svelte / SvelteKit
  8) Solid.js
  9) Astro
  10) Vanilla JS / no framework

Enter number:
```

---

## Step 4 — Rendering strategy

Ask:
```
What is the primary rendering strategy for this application?

  1) CSR — Client-Side Rendering (SPA, React/Vue without SSR)
  2) SSR — Server-Side Rendering (Next.js default, Nuxt SSR, Remix)
  3) SSG — Static Site Generation (Next.js static export, Astro)
  4) ISR — Incremental Static Regeneration (Next.js ISR)
  5) Hybrid — mix of SSR, SSG, and CSR per route

Enter number:
```

---

## Step 5 — Component library and design system

Ask:
```
Does your team use a component library or UI kit?

  1) shadcn/ui         (Radix-based, copy-paste components)
  2) Material UI (MUI) (Google Material Design)
  3) Ant Design
  4) Chakra UI
  5) Radix UI          (unstyled primitives)
  6) Headless UI       (Tailwind-compatible)
  7) Mantine
  8) DaisyUI           (Tailwind plugin)
  9) Vuetify           (Vue)
  10) Angular Material (Angular)
  11) Custom design system (internal)
  12) None

Enter number:
```

---

## Step 6 — Design tool and handoff

Ask:
```
Which design tool does the team use?

  1) Figma
  2) Sketch
  3) Adobe XD
  4) Penpot
  5) Zeplin (handoff tool)
  6) None / design-code by dev

Enter number:
```

If Figma (1):
```
  Figma file URL or team name (for context):
  Is there a Figma design system / component library file? [y/N]
  If yes, URL:

  Do you use Figma tokens plugin (Style Dictionary / Token Studio)? [y/N]
  If yes, path to exported tokens file (e.g. tokens/tokens.json):
```

Ask:
```
Do designs go through a sign-off / review process before development starts? [Y/n]
```

Ask:
```
Do you use Storybook for component development and documentation? [y/N]
If yes, Storybook URL (if hosted):
```

---

## Step 7 — API integration

Ask:
```
How does the frontend communicate with the backend?

  1) REST API (JSON over HTTP)
  2) GraphQL (Apollo Client or urql)
  3) tRPC (type-safe RPC)
  4) gRPC-Web
  5) Mixed

Enter number:
```

Ask:
```
What environment variable holds the API base URL?
(Default: NEXT_PUBLIC_API_URL — press Enter to accept)
```

Ask:
```
How is authentication handled on the frontend?

  1) httpOnly cookie (set by server, invisible to JS — most secure)
  2) localStorage (accessible to JS — XSS risk)
  3) sessionStorage (cleared on tab close)
  4) In-memory only (lost on page refresh)
  5) Handled by auth provider (Auth0, Clerk, NextAuth, etc.)
  6) No auth

Enter number:
```

If choice 5, ask:
```
  Auth provider name (e.g. Auth0, Clerk, NextAuth.js, Supabase Auth, Firebase Auth):
```

---

## Step 8 — Deployment

Ask:
```
Where is the frontend deployed?

  1) Vercel
  2) Netlify
  3) AWS CloudFront + S3 / Lambda@Edge
  4) Google Cloud CDN / Cloud Run
  5) Azure Static Web Apps
  6) GitHub Pages
  7) Self-hosted (nginx, Caddy)
  8) Other

Enter number:
```

Ask:
```
Which CI/CD system handles frontend deployments?
  1) GitHub Actions
  2) GitLab CI
  3) CircleCI
  4) Vercel (built-in deployments)
  5) Netlify (built-in deployments)
  6) Other

Enter number:
```

---

## Step 9 — Monitoring and analytics

Ask:
```
Do you track frontend errors? [y/N]
If yes:
  1) Sentry
  2) Datadog RUM
  3) Bugsnag
  4) Rollbar
  5) Other

Enter number:
```

Ask:
```
Do you monitor Core Web Vitals / performance? [y/N]
If yes:
  1) Vercel Speed Insights
  2) Google Search Console / CrUX
  3) Datadog RUM
  4) Calibre
  5) SpeedCurve
  6) Custom (web-vitals.js + analytics)

Enter number:
```

---

## Step 10 — Feature flags

Ask:
```
Does the frontend use feature flags? [y/N]
If yes:
  1) LaunchDarkly
  2) GrowthBook
  3) Unleash
  4) ConfigCat
  5) Split.io
  6) Environment variables (build-time flags)
  7) Other

Enter number:
```

---

## Step 11 — Ticket system (confirm for frontend)

Read `workflow.config.md`. Confirm:
```
Ticket system from workflow.config.md: <system>
Frontend agents will create tickets and reference designs in <system>.
Is this correct? [Y/n]
```

---

## Step 12 — Write frontend.config.md

Write `frontend.config.md` with all detected and answered values.

---

## Step 13 — Confirm

```
✓ frontend.config.md written.

Frontend Stack:
  Framework       : <framework>
  Language        : <TypeScript strict | TypeScript | JavaScript>
  Rendering       : <strategy>
  Styling         : <approach>
  Component lib   : <library>
  Design tool     : <tool>
  Auth            : <strategy>
  Deployment      : <target>

Next steps:
  /detect-workflow              ← set ticket system + docs (if not done)
  /frontend-sdlc <feature>      ← build your first frontend feature
  /accessibility-audit <file>   ← audit existing components for WCAG compliance
```
