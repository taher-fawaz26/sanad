# Typography

## Source of Truth

Design Tokens define typography. Flutter implementation in `packages/design_system`.

## Architecture

```
Design Tokens
  → TypeScale (English) / ArabicTypeScale (Arabic)
  → AppFont / AppFontArabic (weight presets)
  → AppFontScaleX / AppFontArabicScaleX (size + line-height)
  → AppFontStyle / AppFontArabicStyle (pre-built)
  → AppTypography (ThemeExtension)
```

## Font Families

| Locale | Family | Package Constant |
|--------|--------|---------------|
| English | Inter | `AppFontFamily.inter` |
| Arabic | IBM Plex Sans Arabic | `AppFontFamily.ibmPlexSansArabic` |

## Type Scale

| Tier | Size (dp) | English Line Height | Arabic Line Height |
|------|-----------|--------------------|--------------------|
| Title 1 | 48 | 56 | 60 |
| Title 2 | 32 | 36 | 44 |
| Title 3 | 24 | 32 | 36 |
| Large | 18 | 24 (normal) | 28 (normal) |
| Regular | 16 | 24 (normal) | 26 (normal) |
| Small | 14 | 20 (normal) | 22 (normal) |
| Tiny | 12 | 16 (normal) | 20 (normal) |

Each tier has three line-height variants: **None** (1.0), **Tight**, **Normal**.

## Font Weights

| Weight | Value | Token Status |
|--------|-------|-------------|
| Regular | w400 | In tokens |
| Medium | w500 | **Token gap** — used in Flutter, not yet in tokens |
| SemiBold | w600 | In tokens |
| Bold | w700 | In tokens |

## Title Weights

| Style | Weight | Usage |
|-------|--------|-------|
| Title 1 | Bold w700 | `AppFont.bold.title1` |
| Title 2 | Bold w700 | `AppFont.bold.title2` |
| Title 3 | SemiBold w600 | `AppFont.semiBold.title3` |

## Letter Spacing (Titles)

| Style | Token | Value |
|-------|-------|-------|
| Title 1 | -2% | -0.96px |
| Title 2 | -1% | -0.32px |
| Title 3 | -0.5% | -0.12px |

Applied via `TypeScale.trackingTitle1/2/3` in `AppFontScaleX` title extensions.

## Usage

### In Widgets (Preferred)

```dart
Text('Hello', style: context.appTypography.regularNormal.copyWith(color: colors.textPrimary));
```

### English Composition

```dart
AppFont.regular.regularNormal   // Inter w400, 16/24
AppFont.semiBold.title3         // Inter w600, 24/32
AppFont.bold.title1             // Inter w700, 48/56
```

### Arabic Composition

```dart
AppFontArabic.regular.arRegularNormal  // IBM Plex w400, 16/26
AppFontArabic.semiBold.arTitle3        // IBM Plex w600, 24/36
AppFontArabic.bold.arTitle1            // IBM Plex w700, 48/60
```

## Token Gaps

| Gap | Status |
|-----|--------|
| `FontWeight.w500` (Medium) | Flutter ahead — token team should add |
| `space.json` | Empty — `AppSpacing` in Flutter |
| `shadow.json` | Empty — `AppShadows` in Flutter |
