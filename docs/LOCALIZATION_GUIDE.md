# Localization Guide

## Source of truth

`TranslateBloc` (in `packages/localization`) owns the app language. It is the
**only** persisted locale store, and `EasyLocalization` is a renderer driven
from it by `AppLocaleSync`.

- Default language is **English** (`AppLanguage.defaultLanguage`).
- `AppLanguage` owns every supported `Locale`; never write a `Locale('ar','AR')`
  literal elsewhere (`setLocale` asserts membership of `supportedLocales`).
- `EasyLocalization` is configured with **`saveLocale: false`**. It used to keep
  its own copy in `SharedPreferences['locale']`, which could disagree with the
  bloc — an Arabic UI sending `x-lang: en`, so backend-localized content
  (dashboard card names, `branch.city.name`) came back in English (SAN-774).

## Setup

```dart
// bootstrap.dart — ordering matters, see LegacyLocalePreference.
final legacy = await LegacyLocalePreference.takeIfAny();  // BEFORE the next line
await EasyLocalization.ensureInitialized();
await configureDependencies(
  initialLanguage: legacy ?? AppLanguage.defaultLanguage,
);
if (legacy != null) LegacyLocalePreference.adopt(sl<TranslateBloc>(), legacy);

EasyLocalization(
  supportedLocales: AppLanguage.supportedLocales,
  path: 'packages/localization/assets/translations',
  startLocale: startLanguage.locale,   // seeds the first frame only
  fallbackLocale: AppLanguage.fallbackLocale,
  saveLocale: false,                   // the bloc is the only store
  child: AppLocaleSync(child: app),
)
```

## Translation Files

| File | Locale |
|------|--------|
| `packages/localization/assets/translations/en-US.json` | English (default + fallback) |
| `packages/localization/assets/translations/ar-AR.json` | Arabic |

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

One entry point, from anywhere:

```dart
context.setAppLanguage(AppLanguage.arabic);
```

That dispatches `AppLanguageSelected` on `TranslateBloc` and nothing else.
Everything downstream follows off that single emission:

| Consumer | How it follows |
|---|---|
| `.tr()`, `MaterialApp.locale`, RTL | `AppLocaleSync` calls `setLocale` |
| `Accept-Language` / `x-lang` | `AcceptLanguageInterceptor` reads the bloc per request |
| Language-keyed caches | `keyFor(languageCode: …)` resolved at handle time |
| Backend-localized screens | e.g. `home_page.dart`'s `BlocListener<TranslateBloc>` refetches |

**Never call `context.setLocale` yourself.** `AppLocaleSync` is the only
permitted call site, and a test
(`packages/localization/test/src/locale/single_set_locale_call_site_test.dart`)
enforces that plus `saveLocale: false`. The old pattern — `await setLocale(...)`
then `if (!mounted) return;` then a bloc event — had a window where the UI
changed and the API language did not, and the desync survived restarts because
the two stores persisted independently.

### Backend `preferredLanguage`

An **account** preference for backend-generated content (emails,
notifications). It is written best-effort when the user changes language and is
**never** read back into the runtime locale — the local choice always wins, so a
server value can't flip the UI. Changing the language therefore also works
offline, and for a worker/manager who gets `403` on `PATCH /account-settings`.

## RTL

English is the default locale, but Arabic is a first-class RTL locale — always
verify both:
- Use `EdgeInsetsDirectional` over `EdgeInsets` where direction matters
- Test both `ar-AR` and `en-US` locales
- Directionality comes from `MaterialApp(locale: context.locale)` plus
  `GlobalWidgetsLocalizations`; never hardcode `TextDirection` per page

## Pluralization

Use EasyLocalization `plural()` API — never string interpolation workarounds.
