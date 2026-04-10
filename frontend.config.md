# Claude Crew — Frontend Config
# Run /detect-frontend-stack to auto-fill this file.
# All frontend agents read this before every task.

## Framework & Language

framework: react                # react | vue | angular | svelte | solid | qwik | other
meta_framework: next            # next | nuxt | remix | sveltekit | astro | none
language: typescript            # typescript | javascript
ts_strictness: strict           # strict | moderate | loose (based on tsconfig.json)
node_version: 20

## State Management

state_management: zustand       # redux | zustand | pinia | ngrx | jotai | recoil | context | none
server_state: react-query       # react-query | swr | apollo | urql | rtk-query | none

## Styling

styling: tailwind               # tailwind | css-modules | styled-components | emotion | sass | vanilla-extract | other
component_library: shadcn-ui    # shadcn-ui | mui | ant-design | chakra | radix | headlessui | mantine | custom | none
design_tokens: css-variables    # css-variables | js-tokens | tailwind-config | style-dictionary | none

## Build Tool

build_tool: vite                # vite | webpack | turbopack | rspack | esbuild | parcel | other
package_manager: npm            # npm | yarn | pnpm | bun
bundler_config: vite.config.ts  # path to build config file

## Testing

unit_test_framework: vitest     # jest | vitest | mocha | jasmine
component_test: storybook       # storybook | ladle | none
e2e_framework: playwright       # playwright | cypress | selenium | webdriverio | none
a11y_test_tool: axe             # axe | pa11y | lighthouse | none
test_run_command: npm test

## Rendering

rendering: csr                  # csr | ssr | ssg | isr | hybrid
deployment: vercel              # vercel | netlify | aws-cloudfront | gcp-cdn | azure-static | custom

## Design

design_tool: figma              # figma | sketch | adobe-xd | penpot | other | none
design_system_url:              # URL to Figma/design file or Storybook URL
design_tokens_file:             # path to tokens file if exported (e.g. tokens/tokens.json)

## API Integration

api_style: rest                 # rest | graphql | trpc | grpc | mixed
api_base_url_env: NEXT_PUBLIC_API_URL  # env var name for API base URL
auth_strategy: httponly-cookie  # httponly-cookie | bearer-localStorage | bearer-sessionStorage | none

## Linting & Formatting

linter: eslint                  # eslint | biome | oxlint | none
formatter: prettier             # prettier | biome | none
pre_commit_hook: husky          # husky | lefthook | simple-git-hooks | none

## Feature Flags

feature_flags: none             # launchdarkly | growthbook | unleash | configcat | split | env-vars | none

## Analytics

analytics: none                 # segment | amplitude | mixpanel | ga4 | posthog | none

## Monitoring

error_tracking: none            # sentry | datadog-rum | bugsnag | rollbar | none
performance_monitoring: none    # web-vitals | datadog-rum | newrelic | none

## Workflow Tools
# Set by /detect-workflow

ticket_system: jira             # from workflow.config.md
docs_platform: confluence       # from workflow.config.md
