# Localization Guide

## Setup

```dart
EasyLocalization(
  supportedLocales: [Locale('ar', 'AR'), Locale('en', 'US')],
  path: 'packages/localization/assets/translations',
  startLocale: Locale('ar', 'AR'),      // Arabic is default
  fallbackLocale: Locale('en', 'US'),
  child: app,
)
```

## Translation Files

| File | Locale |
|------|--------|
| `packages/localization/assets/translations/ar-AR.json` | Arabic (default) |
| `packages/localization/assets/translations/en-US.json` | English (fallback) |

## Key Convention

Dot-separated hierarchical keys grouped by domain:

```json
{
  "auth": {
    "login_title": "تسجيل الدخول",
    "password_hint": "كلمة المرور"
  },
  "errors": {
    "no_internet": "لا يوجد اتصال بالإنترنت"
  },
  "branches": {
    "add_branch": {
      "title": "إضافة فرع"
    }
  }
}
```

## Usage in Code

```dart
Text('auth.login_title'.tr())
```

Never hardcode UI strings.

## Adding a New Key

1. Add to `ar-AR.json`
2. Add to `en-US.json`
3. Use `'domain.key'.tr()` in code

Both files must be updated together.

## Validation Messages

Use constants from `ValidationMessageKeys`:

```dart
ValidationMessageKeys.required           // 'validation.form.required'
ValidationMessageKeys.minLength(6)       // 'validation.form.min_length'
ValidationMessageKeys.maxLength(50)      // 'validation.form.max_length'
```

## Error Messages

Use constants from `ErrorMessages` (in `network` package):

```dart
ErrorMessages.noInternet    // 'errors.no_internet'
ErrorMessages.timeout       // 'errors.timeout'
ErrorMessages.unauthorized  // 'errors.unauthorized'
```

## Language Switching

Via `TranslateBloc` (HydratedBloc):

```dart
context.read<TranslateBloc>().add(const TrArabicEvent());
context.read<TranslateBloc>().add(const TrEnglishEvent());
```

Language change also updates `Accept-Language` API header via `AcceptLanguageInterceptor`.

## RTL

Arabic is the default locale. Design RTL first:
- Use `EdgeInsetsDirectional` over `EdgeInsets` where direction matters
- Test both `ar-AR` and `en-US` locales
- `TranslateBloc` drives locale; `EasyLocalization` applies it

## Pluralization

Use EasyLocalization `plural()` API — never string interpolation workarounds.
