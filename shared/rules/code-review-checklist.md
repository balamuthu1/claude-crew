# Code Review Checklist

Apply to every code review:

- [ ] No business logic in Views/Activities/Fragments/ViewControllers
- [ ] No hardcoded strings that should be in resources
- [ ] No API keys or secrets committed
- [ ] Network calls wrapped in try/catch or Result type
- [ ] Lifecycle-aware: no leaks, no crashes on config change
- [ ] Accessibility: content descriptions, minimum touch target 48dp/44pt
- [ ] Tests exist for new public APIs and business logic
