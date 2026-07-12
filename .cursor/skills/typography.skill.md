---
name: typography
description: Typography usage — TypeScale, ArabicTypeScale, AppFont, AppFontArabic, letter-spacing
---

# Typography Skill

Guide for using the Sanad typography system synchronized with design tokens.

## Architecture

```
Design Tokens → TypeScale / ArabicTypeScale → AppFont / AppFontArabic → AppFontStyle / AppFontArabicStyle → AppTypography
```

## English Text

```dart
// In widgets (preferred)
Text('Hello', style: context.appTypography.regularNormal.copyWith(color: colors.textPrimary));

// Composition
Text('Title', style: AppFont.bold.title1);
Text('Body', style: AppFont.regular.regularNormal);
Text('Label', style: AppFont.medium.smallNormal);
```

## Arabic Text

```dart
// Use ArabicTypeScale line heights via AppFontArabicScaleX
Text('مرحبا', style: AppFontArabic.regular.arRegularNormal);
Text('عنوان', style: AppFontArabic.bold.arTitle1);
Text('عنوان فرعي', style: AppFontArabic.semiBold.arTitle3);
```

## Title Weights

| Style | English | Arabic |
|-------|---------|--------|
| Title 1 | `AppFont.bold.title1` | `AppFontArabic.bold.arTitle1` |
| Title 2 | `AppFont.bold.title2` | `AppFontArabic.bold.arTitle2` |
| Title 3 | `AppFont.semiBold.title3` | `AppFontArabic.semiBold.arTitle3` |

## Letter Spacing (Titles Only)

Applied automatically via `AppFontScaleX` title extensions:
- Title 1: -0.96px (48 × -2%)
- Title 2: -0.32px (32 × -1%)
- Title 3: -0.12px (24 × -0.5%)

## Weight Modification in Widgets

```dart
context.appTypography.regularNormal.copyWith(fontWeight: TypeScale.weightBold);
// Or via extension:
context.appTypography.bold(context.appTypography.regularNormal);
```

## Token Gaps

- `FontWeight.w500` (Medium) used but not in design tokens yet
- Do not add new scale entries without design token approval
