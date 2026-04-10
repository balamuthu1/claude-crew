Analyse bundle size and runtime performance for the feature (or whole app) named in the argument. Argument is a feature name or `full` for the whole application.

You are the **orchestrator**. Do NOT analyse code yourself — spawn dedicated sub-agents for each stage using the `Agent` tool. Each sub-agent gets an isolated context window focused on its domain.

---

## Before starting

Read `frontend.config.md` and `workflow.config.md`. Extract:
- `{{FEATURE}}` — argument passed to this command (`full` or a feature name)
- `{{FRAMEWORK}}` — e.g. `React 18 + Next.js 14`
- `{{BUILD_TOOL}}` — `vite` | `webpack` | `turbopack` | `rspack` | `parcel`
- `{{BUNDLER_CONFIG}}` — path to build config file (e.g. `vite.config.ts`, `next.config.js`, `webpack.config.js`)
- `{{PACKAGE_MANAGER}}` — `npm` | `yarn` | `pnpm` | `bun`
- `{{PERF_MONITORING}}` — from `performance_monitoring` field: `sentry` | `datadog-rum` | `newrelic` | `web-vitals` | `none`
- `{{ERROR_TRACKING}}` — from `error_tracking` field
- `{{TICKET_SYSTEM}}` — from `workflow.config.md`
- `{{RENDERING}}` — `csr` | `ssr` | `ssg` | `isr` | `hybrid`

If `claude-crew.config.md` or `frontend.config.md` does not exist, note the gap and suggest running `/detect-frontend-stack`, then continue with best-effort values.

---

## Stage Definitions

### Stage 1 — BUNDLE AUDIT
Spawn the `frontend-architect` agent.

Agent prompt:
```
You are the frontend-architect agent performing a bundle size audit.

Feature / scope: {{FEATURE}}
Framework: {{FRAMEWORK}}
Build tool: {{BUILD_TOOL}}
Build config file: {{BUNDLER_CONFIG}}
Package manager: {{PACKAGE_MANAGER}}

Read frontend.config.md. Then perform a static bundle audit of the codebase.
This is grep-based static analysis — no build execution required.

---

### 1. Barrel file analysis
Search for index.ts / index.js files that re-export large slices of a directory.
Barrel files disable tree-shaking because bundlers cannot statically determine
which exports are used when a barrel re-exports everything.

Flag any file matching:
- `export * from './...'` with more than 5 re-exports in a single barrel
- Barrel files sitting in `components/`, `utils/`, `hooks/`, or `features/` directories
- Barrel files imported by route-level components (worst case: entire barrel in initial bundle)

For each finding: file path, number of re-exports, which routes import it.

### 2. Whole-library import patterns
Search for import statements that pull in entire libraries instead of
specific named exports. These prevent tree-shaking and bloat the bundle.

Patterns to find:
- `import _ from 'lodash'` or `import lodash from 'lodash'` — should be `import debounce from 'lodash/debounce'`
- `import * as Icons from 'react-icons/fi'` or any `import * as` from an icon library
- `import { Component1, Component2, Component3, ... } from 'some-ui-lib'` where 5+ named imports
  suggest the whole package is being consumed (check if the library supports subpath imports)
- `import moment from 'moment'` — 300kB; suggest date-fns or dayjs
- `import { format, parseISO, addDays, ... } from 'date-fns'` without tree-shaking config — verify
  `date-fns` v3+ is used (ESM); v2 requires explicit `/esm/` subpath imports
- `import * as R from 'ramda'`
- Full `@mui/icons-material` or `@ant-design/icons` imports rather than deep path imports

For each finding: file path, line number, library name, estimated size impact.

### 3. Missing lazy loading on routes
In a {{FRAMEWORK}} app, route-level components should be code-split so the
initial bundle only contains code for the first rendered route.

Find route components that are statically imported instead of lazily loaded:
- Files in `pages/`, `app/`, or `routes/` directories that are imported with
  `import ComponentName from '...'` rather than `React.lazy(...)` or `dynamic(...)`
- Router definitions (react-router, next.js app router, TanStack Router) where
  `component:` or `element:` receives a statically imported component larger than
  ~20kB (check file size with Glob)
- For Next.js: any `import` in a page file that is not using `next/dynamic` for
  heavy client-only libraries (charts, rich text editors, maps, syntax highlighters)

### 4. Heavy dependencies inventory
Read `package.json`. Flag these known-heavy packages:
- `moment` — ~300kB minified; suggest `date-fns` (tree-shakable) or `dayjs` (~7kB)
- `lodash` (not `lodash-es`) — ~70kB; suggest `lodash-es` or per-method imports
- `@fullcalendar/*` — large; confirm only loaded on pages that need it
- `react-pdf` / `pdfjs-dist` — very large (~1MB); must be dynamically imported
- `monaco-editor` / `@monaco-editor/react` — very large (~2MB); must be dynamically imported
- `mapbox-gl` / `react-map-gl` / `leaflet` — large; must be dynamically imported
- `recharts` / `chart.js` / `echarts` — medium-large; lazy load where possible
- `@tiptap/*` / `slate` / `quill` — rich text editors; must be dynamically imported
- `xlsx` / `exceljs` — large; should only load on demand
- `three` / `@react-three/fiber` — very large; dynamic import mandatory

For each: package name, approx. minified+gzipped size, whether dynamic import is applied.

### 5. Duplicate dependency detection
Read `package.json` and any lock file (`package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`).
Look for:
- The same package appearing at multiple version ranges (e.g. `react-router` 5 AND 6)
- Packages with known duplicate-prone ecosystems: `@babel/runtime`, `tslib`, `lodash` vs `lodash-es`
- Peer dependency mismatches that cause npm to hoist duplicates

### 6. Development packages in production imports
Search for imports of packages that should only appear in devDependencies:
- `import ... from 'storybook'` or `@storybook/*` in non-story files
- `import ... from 'vitest'` or `jest` in non-test source files
- `import ... from '@testing-library/*'` outside of `__tests__` or `*.test.*` files
- `import ... from 'webpack'` or `vite` in runtime application code

### 7. Image optimization gaps
Search for:
- `<img src=` not using `next/image` (for Next.js) — missing automatic optimization
- `<img` without explicit `width` and `height` attributes — causes CLS
- `<img` without `loading="lazy"` on below-the-fold images
- Large images imported directly: `import heroImage from './hero.jpg'` in bundle
  (should reference via public URL or CDN, not bundled)
- SVGs inlined as React components that are large (>5kB SVG source) — consider
  external URL instead

### 8. Font loading
Check for synchronous font loading that blocks rendering:
- `<link rel="stylesheet" href="https://fonts.googleapis.com/...">` without
  `rel="preconnect"` hint above it
- CSS `@font-face` rules without `font-display: swap` or `font-display: optional`
- Fonts loaded via `@import` inside CSS files (slower than `<link>` in HTML head)

---

### Output format

Produce a prioritised findings list:

**P0 — Critical (immediate bundle impact >50kB per issue)**
- [ISSUE TYPE] File/package — Description — Estimated saving

**P1 — High (10–50kB impact or code splitting gap on a primary route)**
- [ISSUE TYPE] File/package — Description — Estimated saving

**P2 — Medium (best practice gap, <10kB or secondary routes)**
- [ISSUE TYPE] File/package — Description — Estimated saving

**Summary line:**
Total P0: N, P1: N, P2: N — Estimated recoverable bundle size: ~NkB gzipped

Tools: Read, Grep, Glob
```

Gate: Print the audit summary line (P0/P1/P2 counts and estimated savings). Ask:

```
Bundle Audit complete — P0: N, P1: N, P2: N, ~NkB recoverable.
Proceed to PERFORMANCE AUDIT? [y/N]
```

Wait for user confirmation before continuing.

---

### Stage 2 — PERFORMANCE AUDIT
Spawn the `frontend-architect` agent.

Agent prompt:
```
You are the frontend-architect agent performing a runtime performance audit.

Feature / scope: {{FEATURE}}
Framework: {{FRAMEWORK}}
Rendering strategy: {{RENDERING}}

Read frontend.config.md. Perform a static analysis of runtime performance issues.
No build or execution required — analyse source code patterns.

---

### 1. Unnecessary re-render analysis
Search for components that will re-render more than necessary:

**Missing memoization:**
- Functional components exported without `React.memo` that receive stable prop shapes
  and appear in lists or are children of frequently-updating parents
- Inline object or array creation in JSX props: `<Component style={{ margin: 8 }}>`
  or `<Component items={[a, b, c]}>` — new reference every render
- Inline function creation in JSX: `<Button onClick={() => handleClick(id)}>`
  without useCallback wrapping — stable callbacks should be memoized
- `useMemo` or `useCallback` with empty dependency arrays `[]` where the value
  actually depends on props/state (stale closure bug, also a correctness issue)

**Context re-render traps:**
- React Context providers that hold a large object in value where any field change
  re-renders ALL consumers — check for `value={{ user, settings, theme, ... }}`
  patterns; each concern should be a separate context or use a state manager slice
- Context consumers that only need one field from a multi-field context object
  without a selector or split context

**useEffect problems:**
- `useEffect` with object or array dependencies created inside the component body
  (new reference every render → infinite loop risk or excessive effect runs):
  `useEffect(() => { ... }, [{ id: userId }])` — destructure primitives instead
- Missing cleanup functions for subscriptions, timers, or event listeners:
  `addEventListener` without corresponding `removeEventListener` in cleanup

### 2. Expensive computation in render
Search for:
- Heavy synchronous computations called directly in component body without `useMemo`:
  `.sort()`, `.filter()`, `.reduce()` on large arrays, `.map()` with complex transforms
- Date formatting or locale-sensitive operations in render without memoization
- Regular expression construction inside render: `new RegExp(...)` every render
- Deeply nested object transformations in render path

### 3. Large list virtualization gaps
Identify components that render long lists without virtualization:
- `.map()` rendering more than ~50 items in a scrollable container without
  `react-window`, `react-virtual` (`@tanstack/virtual`), or `react-virtuoso`
- Tables rendering more than ~100 rows without pagination or virtualization
- Infinite scroll implementations that retain ALL previous items in the DOM
  (items should be recycled via virtualization)

### 4. Data fetching performance
Audit API call patterns:

**Waterfall requests:**
- Sequential `await fetch(url1); await fetch(url2);` calls inside the same
  async function or useEffect that could be `Promise.all([fetch(url1), fetch(url2)])`
- Component trees where child component starts a fetch only after parent fetch
  resolves, when child's fetch does not depend on parent's data
- React Query / SWR: dependent queries used where parallel queries would work

**Missing prefetching:**
- Navigation links to routes that load heavy data without `prefetch` or
  hover-triggered prefetch (react-query `prefetchQuery`, Next.js `router.prefetch`)
- Tabs or drawers that fetch data only on open — data should be prefetched on hover

**Over-fetching:**
- GraphQL queries that select `__typename` fields and all scalars instead of
  just needed fields
- REST calls that return large payloads but only display a few fields (note as
  a candidate for a more targeted endpoint)

**Stale-while-revalidate missing:**
- React Query queries with `staleTime: 0` (default) for data that changes infrequently
  — suggest appropriate `staleTime` and `gcTime` values

### 5. Animation and layout performance
Search for CSS and animation anti-patterns:
- CSS transitions or animations on `width`, `height`, `top`, `left`, `margin`,
  or `padding` — these trigger layout (reflow); prefer `transform` and `opacity`
- JavaScript-driven animations using `setInterval` or `setTimeout` instead of
  `requestAnimationFrame` or CSS transitions
- Scroll event listeners without throttle/debounce and without passive flag:
  `addEventListener('scroll', handler)` → should be `{ passive: true }`
- `document.querySelectorAll` or DOM reads inside animation loops (layout thrash)

### 6. Core Web Vitals risk assessment
Based on the code patterns found above, assess risk for each CWV metric:

**LCP (Largest Contentful Paint) — target <2.5s**
- Is there a hero image, hero text block, or large card above the fold?
- Is the LCP element's resource preloaded? (`<link rel="preload">` or
  `fetchpriority="high"` on the img)
- Does the LCP element depend on a client-side data fetch before it can render?
  (SSR or SSG would help here)

**CLS (Cumulative Layout Shift) — target <0.1**
- Images without `width` / `height` attributes (or `aspect-ratio` CSS)
- Fonts loading without `font-display: swap` causing FOUT/FOIT layout shift
- Ads, embeds, or iframes without reserved space
- Dynamically injected banners or cookie consent bars above page content
- Skeleton screens that are a different height than the content they replace

**INP (Interaction to Next Paint) — target <200ms**
- Long synchronous tasks (>50ms) in event handlers
- Expensive state updates triggered by keypress or click without debouncing
- Heavy initial hydration bundles causing long tasks during page load
- Blocking third-party scripts loaded synchronously in `<head>`

---

### Output format

**Rendering Performance Findings:**
| Priority | Category | File:Line | Issue | Fix |
|----------|----------|-----------|-------|-----|

**Data Fetching Findings:**
| Priority | Pattern | Location | Issue | Fix |

**Core Web Vitals Risk Summary:**
- LCP risk: [Low/Medium/High] — [reason]
- CLS risk: [Low/Medium/High] — [reason]
- INP risk: [Low/Medium/High] — [reason]

**Summary line:**
CWV risks: N, Re-render issues: N, Data fetching issues: N, Animation issues: N

Tools: Read, Grep, Glob
```

Gate: Print the performance audit summary line. Ask:

```
Performance Audit complete — CWV risks: N, Re-render issues: N, Data fetching: N.
Proceed to OPTIMIZATION PLAN? [y/N]
```

Wait for user confirmation before continuing.

---

### Stage 3 — OPTIMIZATION PLAN
Spawn the `frontend-developer` agent.

Agent prompt:
```
You are the frontend-developer agent producing an optimization plan.

Feature / scope: {{FEATURE}}
Framework: {{FRAMEWORK}}
Build tool: {{BUILD_TOOL}}
Bundler config: {{BUNDLER_CONFIG}}
Package manager: {{PACKAGE_MANAGER}}
Performance monitoring: {{PERF_MONITORING}}
Ticket system: {{TICKET_SYSTEM}}

Bundle audit findings (Stage 1):
{{BUNDLE_AUDIT_OUTPUT}}

Performance audit findings (Stage 2):
{{PERF_AUDIT_OUTPUT}}

Read frontend.config.md. Then produce the full optimization plan.

---

### 1. P0 and P1 fix specifications
For every P0 and P1 finding from Stages 1 and 2, produce an entry in this format:

---
**[FINDING ID] — [Finding title]**
Priority: P0 / P1
Category: Bundle size / Render performance / CWV / Data fetching
Estimated improvement: ~NkB reduction / ~Nms faster INP / CLS eliminated

Before:
```[language]
// exact problematic code from the file
```

After:
```[language]
// exact corrected code
```

Effort: S (< 1h) / M (half day) / L (> 1 day)
Notes: [Any caveats, migration steps, or peer review required]

Ticket: Create "[{{TICKET_SYSTEM}} ticket]" →
  Summary: "Perf: [one-line description]"
  Type: Task
  Priority: P0 → Blocker | P1 → High
  Labels: performance, frontend
  Description: [2-3 sentences describing the issue and the fix]
---

### 2. Bundle budget file
Produce the appropriate bundle budget configuration for {{BUILD_TOOL}}.

**For Vite (`vite.config.ts`):**
Add `build.chunkSizeWarningLimit` and a `rollup-plugin-visualizer` integration:
```typescript
// vite.config.ts addition
import { visualizer } from 'rollup-plugin-visualizer';

export default defineConfig({
  build: {
    chunkSizeWarningLimit: 300, // kB — warn if any chunk exceeds 300kB
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['react', 'react-dom'],
          router: ['react-router-dom'],
          // Add other stable third-party chunks here
        },
      },
    },
  },
  plugins: [
    visualizer({
      filename: 'dist/bundle-stats.html',
      gzipSize: true,
      brotliSize: true,
      open: false, // set true locally, false in CI
    }),
  ],
});
```

**For webpack (`webpack.config.js` or `next.config.js`):**
```javascript
// next.config.js addition (Next.js)
const withBundleAnalyzer = require('@next/bundle-analyzer')({
  enabled: process.env.ANALYZE === 'true',
});

module.exports = withBundleAnalyzer({
  experimental: {
    // Enforce size budgets
  },
});
// Run with: ANALYZE=true next build
```

**Lighthouse CI budget (`lighthouserc.js`):**
```javascript
module.exports = {
  ci: {
    collect: { startServerCommand: '{{PACKAGE_MANAGER}} run build && {{PACKAGE_MANAGER}} run start' },
    assert: {
      assertions: {
        'categories:performance': ['error', { minScore: 0.8 }],
        'first-contentful-paint': ['error', { maxNumericValue: 2000 }],
        'largest-contentful-paint': ['error', { maxNumericValue: 2500 }],
        'cumulative-layout-shift': ['error', { maxNumericValue: 0.1 }],
        'total-blocking-time': ['error', { maxNumericValue: 300 }],
        'resource-summary:script:size': ['error', { maxNumericValue: 500000 }], // 500kB JS
      },
    },
    upload: { target: 'temporary-public-storage' },
  },
};
```

Write the appropriate file(s) for {{BUILD_TOOL}}. If the config file already
exists, show a patch (before/after) rather than replacing the whole file.

### 3. Performance monitoring setup
Based on {{PERF_MONITORING}}, provide setup instructions:

**If {{PERF_MONITORING}} is `sentry`:**
```typescript
// In your app entry point (main.tsx / _app.tsx)
import * as Sentry from '@sentry/react';
Sentry.init({
  integrations: [
    Sentry.browserTracingIntegration(),
    Sentry.replayIntegration({ maskAllText: true }),
  ],
  tracesSampleRate: 0.1,      // 10% of transactions
  replaysOnErrorSampleRate: 1.0,
});
// Add Web Vitals reporting:
import { onCLS, onINP, onLCP } from 'web-vitals';
onCLS(({ value }) => Sentry.captureMessage('CLS', { extra: { value } }));
onINP(({ value }) => Sentry.captureMessage('INP', { extra: { value } }));
onLCP(({ value }) => Sentry.captureMessage('LCP', { extra: { value } }));
```

**If {{PERF_MONITORING}} is `datadog-rum`:**
```typescript
import { datadogRum } from '@datadog/browser-rum';
datadogRum.init({
  applicationId: process.env.NEXT_PUBLIC_DD_APP_ID,
  clientToken: process.env.NEXT_PUBLIC_DD_CLIENT_TOKEN,
  site: 'datadoghq.com',
  sessionSampleRate: 10,
  sessionReplaySampleRate: 5,
  trackUserInteractions: true,
  trackResources: true,
  trackLongTasks: true,
  defaultPrivacyLevel: 'mask',
});
```

**If {{PERF_MONITORING}} is `web-vitals` or `none`:**
```typescript
// web-vitals.ts — standalone reporting
import { onCLS, onINP, onLCP, onFCP, onTTFB } from 'web-vitals';
type MetricName = 'CLS' | 'INP' | 'LCP' | 'FCP' | 'TTFB';
function sendToAnalytics({ name, value, id }: { name: MetricName; value: number; id: string }) {
  // Replace with your analytics endpoint
  navigator.sendBeacon('/api/vitals', JSON.stringify({ name, value, id }));
}
onCLS(sendToAnalytics);
onINP(sendToAnalytics);
onLCP(sendToAnalytics);
onFCP(sendToAnalytics);
onTTFB(sendToAnalytics);
```
Also recommend adding Lighthouse CI to the GitHub Actions workflow (or equivalent CI).

### 4. Quick-win prioritization table
| # | Finding | Category | Effort | Bundle Save | Perf Gain |
|---|---------|----------|--------|-------------|-----------|
| 1 | ...     | ...      | S      | ~NkB        | —         |

Sort by: highest impact ÷ lowest effort first.

Tools: Read, Write
```

After Stage 3 completes, print the final summary report:

```
════════════════════════════════════════════════════════
  Bundle Analysis — {{FEATURE}}
════════════════════════════════════════════════════════
  [✓] Stage 1 — BUNDLE AUDIT     P0: N, P1: N, P2: N  Est. savings: ~NkB gzipped
  [✓] Stage 2 — PERFORMANCE      CWV risks: N, Re-render: N, Data fetching: N
  [✓] Stage 3 — OPTIMIZATION     P0 fixes: N, P1 fixes: N, Budget file written
════════════════════════════════════════════════════════

Tickets to create in {{TICKET_SYSTEM}}:
  P0 (Blocker):
    - [list each P0 finding with one-line summary]
  P1 (High):
    - [list each P1 finding with one-line summary]

Recommended CI addition: lighthouserc.js budget assertions
Next step: run `{{PACKAGE_MANAGER}} run build` and open dist/bundle-stats.html
```

---

## Variables

- `{{FEATURE}}` = argument passed to this command (`full` or feature name)
- `{{FRAMEWORK}}` = from `frontend.config.md` → `framework` + `meta_framework`
- `{{BUILD_TOOL}}` = from `frontend.config.md` → `build_tool`
- `{{BUNDLER_CONFIG}}` = from `frontend.config.md` → `bundler_config`
- `{{PACKAGE_MANAGER}}` = from `frontend.config.md` → `package_manager`
- `{{RENDERING}}` = from `frontend.config.md` → `rendering`
- `{{PERF_MONITORING}}` = from `frontend.config.md` → `performance_monitoring`
- `{{ERROR_TRACKING}}` = from `frontend.config.md` → `error_tracking`
- `{{TICKET_SYSTEM}}` = from `workflow.config.md` → `ticket_system`
- `{{BUNDLE_AUDIT_OUTPUT}}` = Stage 1 output (first 3000 chars)
- `{{PERF_AUDIT_OUTPUT}}` = Stage 2 output (first 3000 chars)
