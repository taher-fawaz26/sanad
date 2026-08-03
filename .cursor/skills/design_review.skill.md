---
name: design_review
description: Review UI consistency with Design System — components, typography, colors, spacing, tokens
---

# Design Review Skill

Review UI code for Design System compliance.

## Component Audit

- [ ] Every interactive element uses DS components (`AppButton`, `AppTextField`, `AppSelectField`)
- [ ] Navigation uses `AppNavBar`, `AppLargeNavBar`
- [ ] Sections use `AppSection` with correct tone
- [ ] No custom-built equivalents of DS components

## Typography Review

```bash
# Grep for violations
rg "TextStyle\(" --glob "*.dart" -g "!packages/design_system/**"
rg "fontSize:" --glob "*.dart" -g "!packages/design_system/**"
```

- [ ] All text uses `context.appTypography.*` or `AppFont.*`
- [ ] Arabic text uses `AppFontArabic.*` / `AppFontArabicStyle.*`
- [ ] Title 3 uses SemiBold, Title 1/2 use Bold

## Color Usage

```bash
rg "Colors\." --glob "*.dart" -g "!packages/design_system/**"
rg "Color\(0x" --glob "*.dart" -g "!packages/design_system/**"
```

- [ ] All colors from `context.appColors.*`
- [ ] No hex literals outside palette files

## Spacing Validation

```bash
rg "EdgeInsets\." --glob "*.dart" -g "!packages/design_system/**"
```

- [ ] All spacing from `AppSpacing.*`
- [ ] No numeric padding/margin literals

## Token Compliance

- [ ] Radius: `AppRadius.*`
- [ ] Shadows: `AppShadows.*`
- [ ] Dimensions: `AppDimension.*`
- [ ] Durations: `AppDurations.*`

## Accessibility

- [ ] Minimum tap targets 48×48 dp
- [ ] `Semantics` labels on icon-only buttons
- [ ] Sufficient color contrast (text on background)

## Responsive Review

- [ ] No hardcoded widths/heights
- [ ] Test at 360px and 428px design widths
- [ ] Uses `ScreenUtilInit` wrapper in tests

## Output

Report as **Critical** / **Warning** / **Suggestion** with file:line and fix.
