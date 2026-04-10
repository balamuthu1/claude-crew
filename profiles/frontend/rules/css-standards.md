# CSS Standards

These rules apply to all CSS, SCSS, and CSS-in-JS styling.

## Methodology

Use the project's declared approach from `frontend.config.md`. Default priority:
1. CSS Modules (scoped by default, no runtime)
2. Tailwind CSS (utility-first, zero specificity fights)
3. styled-components/emotion (co-located, dynamic)
4. BEM (global CSS, large teams)

Never mix methodologies within a project without justification.

## Core rules

### No `!important`
Solve specificity conflicts by restructuring, not overriding.

### No magic values
All spacing, colours, and typography come from design tokens:
```css
/* Wrong */
.button { padding: 12px 24px; color: #4f46e5; }

/* Correct */
.button { padding: var(--space-3) var(--space-6); color: var(--color-primary); }
```

### No inline styles (except dynamic values)
```tsx
// Wrong
<div style={{ padding: '16px', color: 'red' }} />

// Correct
<div className={styles.container} />

// Acceptable (truly dynamic)
<div style={{ height: `${dynamicHeight}px` }} />
```

### No `display: none` for responsive hiding
Use CSS Grid/Flexbox with `min-width`/`max-width` media queries:
```css
/* Correct responsive pattern */
.grid {
  display: grid;
  grid-template-columns: 1fr;
}
@media (min-width: 768px) {
  .grid { grid-template-columns: 1fr 1fr; }
}
```

## Design token naming

```css
:root {
  /* Spacing — 4px base unit */
  --space-0: 0;
  --space-1: 4px;
  --space-2: 8px;
  --space-3: 12px;
  --space-4: 16px;
  --space-6: 24px;
  --space-8: 32px;
  --space-12: 48px;
  --space-16: 64px;

  /* Colours — semantic names */
  --color-primary: #4f46e5;
  --color-primary-hover: #4338ca;
  --color-text: #111827;
  --color-text-muted: #6b7280;
  --color-surface: #ffffff;
  --color-border: #e5e7eb;

  /* Typography */
  --font-sans: system-ui, -apple-system, sans-serif;
  --text-xs: 12px;
  --text-sm: 14px;
  --text-base: 16px;
  --text-lg: 18px;
  --text-xl: 20px;
  --text-2xl: 24px;

  /* Radius */
  --radius-sm: 4px;
  --radius-md: 8px;
  --radius-lg: 12px;
  --radius-full: 9999px;
}
```

## Animation standards

- Keep transitions ≤ 200ms for immediate feedback; ≤ 400ms for complex transitions
- Use `transform` and `opacity` for GPU-composited transitions
- Never animate `width`, `height`, `top`, `left` (triggers layout reflow)
- Always respect `prefers-reduced-motion`:

```css
@media (prefers-reduced-motion: reduce) {
  * { animation-duration: 0.01ms !important; transition-duration: 0.01ms !important; }
}
```

## Accessibility in CSS

- Never remove `outline` without providing an alternative focus indicator
- Minimum touch target size: 44×44px
- Minimum click target size: 24×24px
- Colour cannot be the only way to convey information (add icons, text, patterns)
