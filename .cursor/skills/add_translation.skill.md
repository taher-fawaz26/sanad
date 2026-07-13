# Add Translation Skill

Triggered when the user says "add a translation key", "add localization", or "translate this string".

## Workflow

1. Read `packages/localization/assets/translations/en-US.json`
2. Read `packages/localization/assets/translations/ar-AR.json`
3. Add key to **both** files under the correct feature namespace
4. Use `'feature.key'.tr()` in code — never hardcode user-facing strings
5. Run `melos validate:l10n`

## Naming

```
feature.action_label
feature.empty_title
feature.empty_description
errors.specific_error
```

## Rules

- Arabic must not be left empty in production PRs
- Pluralization via EasyLocalization `plural()` API
- See `docs/LOCALIZATION_GUIDE.md`
