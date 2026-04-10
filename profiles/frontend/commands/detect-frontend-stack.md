---
description: Auto-detect the frontend tech stack and write frontend.config.md. Reads package.json, tsconfig.json, vite.config, webpack.config, .eslintrc.
---

Detect the project's frontend stack by reading:
- `package.json` (framework, state management, styling, test framework)
- `tsconfig.json` (TypeScript strictness)
- `vite.config.*` / `webpack.config.*` / `next.config.*` (build tool)
- `.eslintrc*` (linting rules)
- `tailwind.config.*` (CSS framework)

From these, determine:
- Framework (React, Vue, Angular, Svelte, etc.)
- TypeScript usage and strictness level
- State management (Redux, Zustand, Pinia, NgRx, etc.)
- Styling approach (CSS Modules, Tailwind, styled-components, etc.)
- Build tool (Vite, Webpack, Turbopack, etc.)
- Test framework (Jest, Vitest, Cypress, Playwright, etc.)
- Rendering strategy (SPA, SSR via Next.js/Nuxt, static)

Write `frontend.config.md`:

```yaml
framework: <react|vue|angular|svelte|...>
language: typescript|javascript
ts_strictness: strict|moderate|loose
state_management: <redux|zustand|pinia|ngrx|context|...>
styling: <tailwind|css-modules|styled-components|emotion|...>
build_tool: <vite|webpack|turbopack|...>
testing: <jest|vitest|cypress|playwright|...>
rendering: <spa|ssr|ssg|...>
```

Write the file and confirm.
