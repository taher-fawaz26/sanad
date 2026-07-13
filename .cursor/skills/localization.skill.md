---
name: localization
description: Add translations — keys, both JSONs, ValidationMessageKeys, TranslateBloc
---

# Localization Skill

Add or update translations in the Sanad monorepo.

## Files

- `packages/localization/assets/translations/ar-AR.json` (default locale)
- `packages/localization/assets/translations/en-US.json` (fallback)

## Adding a New Key

1. Add to `ar-AR.json`:
```json
{
  "feature": {
    "title": "عنوان الميزة",
    "description": "وصف الميزة"
  }
}
```

2. Add to `en-US.json`:
```json
{
  "feature": {
    "title": "Feature Title",
    "description": "Feature description"
  }
}
```

3. Use in code:
```dart
Text('feature.title'.tr())
```

## Key Convention

Dot-separated, grouped by domain:
- `auth.login_title`
- `errors.no_internet`
- `branches.add_branch.title`
- `validation.form.required`

## Validation Messages

Use constants, not raw strings:
```dart
ValidationMessageKeys.required  // 'validation.form.required'
ValidationMessageKeys.minLength(6)  // 'validation.form.min_length'
```

## Error Messages

```dart
ErrorMessages.noInternet  // 'errors.no_internet'
ErrorMessages.timeout     // 'errors.timeout'
```

## Language Switching

```dart
context.read<TranslateBloc>().add(const TrArabicEvent());
context.read<TranslateBloc>().add(const TrEnglishEvent());
```

## RTL

Arabic is default — design RTL first. Test both locales after adding keys.
