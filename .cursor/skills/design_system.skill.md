---
name: design_system
description: Build a new Design System component — tokens, component, barrel export
---

# Design System Skill

Create a new component in `packages/design_system`.

## Step 1 — Token File

```dart
// lib/src/theme/tokens/my_component_tokens.dart
abstract final class MyComponentTokens {
  MyComponentTokens._();

  static const double height = 48;
  static const double borderRadius = 12;

  static MyComponentStyleSpec resolve({
    required AppColors colors,
    required AppTypography typography,
    required Brightness brightness,
  }) { /* ... */ }
}
```

## Step 2 — Component

```dart
// lib/src/components/app_my_component.dart
class AppMyComponent extends StatelessWidget {
  const AppMyComponent({required this.label, super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final spec = MyComponentTokens.resolve(
      colors: colors, typography: typography,
      brightness: Theme.of(context).brightness,
    );
    // Build using tokens only — no hardcoded values
  }
}
```

## Step 3 — Export

Add to `packages/design_system/lib/design_system.dart`:
```dart
export 'src/components/app_my_component.dart';
export 'src/theme/tokens/my_component_tokens.dart';
```

## Compliance Checklist

- [ ] No `Colors.*` or hex literals
- [ ] No raw `TextStyle`, `EdgeInsets`, `BorderRadius`
- [ ] Uses `AppSpacing`, `AppRadius`, `AppTypography`
- [ ] Token file for all style values
- [ ] Exported in barrel file
- [ ] Update `docs/DESIGN_SYSTEM.md`

## Domain-Aware Widgets

If the component needs domain logic (e.g. OTP field), create in `packages/shared_widgets/` instead.
