# Localization Rules

Package: [`packages/localization/`](../../packages/localization/) (`easy_localization`).
Translations: `packages/localization/assets/translations/en-US.json`, `ar-AR.json`.
Detail: [`docs/LOCALIZATION_GUIDE.md`](../../docs/LOCALIZATION_GUIDE.md).

## Mandatory

- Every user-facing string is a key in **both** `en-US.json` and `ar-AR.json`,
  resolved via `'key.path'.tr()` (or `.tr(namedArgs: {...})` for interpolation).
- Keys must exist in all locale files — parity is enforced by
  `melos run validate:l10n`. Add a key to every locale in the same change.
- Arabic is a first-class RTL locale; verify layout and any AM/PM / number /
  date formatting in Arabic, not only English.
- Convert `Failure`s to display text with `failure.localizedMessage()`, which
  detects whether the message is an i18n key or already-localized backend prose —
  do not `.tr()` raw backend messages.

## Do Not

- Do not hardcode display strings in widgets or blocs.
- Do not add a key to one locale and not the others (breaks `validate:l10n`).
- Do not localize backend-supplied dynamic messages by guessing a key.

## Preferred

- Prefer `intl`/locale-aware formatters (e.g. `DateFormat('h:mm a')` for 12-hour
  AM/PM) over manual string building or `DateFormat.jm()` whose skeleton follows
  the device locale.
- Prefer namespaced key paths grouped by feature (`settings.*`, `registration.*`,
  `otp.*`).

## Validation

- `melos run validate:l10n` — asserts all keys present in all locales.
