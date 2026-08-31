# UI / Design System Rules

Foundation: [`packages/design_system/`](../../packages/design_system/) (tokens, theme, atoms).
Application-UI layer: [`packages/shared_ui/`](../../packages/shared_ui/) (composed widgets, pages, pagination).
Detail: [`docs/DESIGN_SYSTEM.md`](../../docs/DESIGN_SYSTEM.md), [`docs/TYPOGRAPHY.md`](../../docs/TYPOGRAPHY.md).
Decision: [`docs/adr/0003-design-system-tokens.md`](../../docs/adr/0003-design-system-tokens.md).

## Mandatory

- Build screens from design-system components (`App*` widgets — `AppButton`,
  `AppOtpField`, `AppScrollPage`, `AppSliverAppBar`, snackbars, etc.), not raw
  Material widgets styled inline.
- Read colors, spacing, and typography from tokens/extensions
  (`context.appColors`, `context.appTypography`, `AppSpacing`, `AppDimension`,
  `responsiveDimension`), never hardcoded hex/px.
- All user-facing strings are localization keys resolved with `.tr()`
  (see [localization.md](localization.md)); no hardcoded display text.
- Respect RTL: rely on directional widgets/`EdgeInsetsDirectional`; only force
  `TextDirection.ltr` for intrinsically-LTR content (e.g. OTP digits) as done in
  `AppOtpField`.
- Displaying an inherently-LTR **value** (phone number, email, URL, handle) as
  read-only text under an RTL layout: wrap it with `String.ltrIsolated`
  (`design_system`) so a bidi-neutral leading `+` renders at the visual start,
  not the end (the recurring SAN-770/771/775 bug). For a whole read-only field
  or a key/value row, prefer the component flags that do this for you —
  `AppTextField(isLtr: true)` / `AppPhoneField`, `AppKeyValueCard(isLtr: true)`,
  `GroupedKeyValueItem(isLtr: true)`. Prefer `ltrIsolated` over a bare
  `TextDirection.ltr`: the isolate also stops the value from reordering adjacent
  Arabic text.
- Keep feature widgets under the feature's `presentation/widgets/`; promote a
  widget to `shared_ui`/`design_system` only when it is genuinely reusable.
- Present bottom sheets/modals via `SheetNavigator` (`packages/sheet_navigation`),
  not `showModalBottomSheet` — see [routing.md](routing.md).

## Do Not

- Do not let `design_system` or `shared_ui` depend on feature packages
  (enforced by `dep_rules.yaml`); reuse flows the other way.
- Do not hardcode colors, font sizes, spacing, or copy.
- Do not put business logic or network calls in widgets (see
  [state-management.md](state-management.md)).

## Preferred

- Preview/iterate new components in the `design_catalog` app.
- Prefer `responsiveDimension`/responsive spacing helpers for sizing.

## Validation

- `melos run analyze`; visual check via `design_catalog`.
