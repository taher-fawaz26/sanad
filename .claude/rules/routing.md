# Routing Rules

Solution: **go_router**. Decision: [`docs/adr/0007-go-router.md`](../../docs/adr/0007-go-router.md).
Detail: [`docs/ROUTING.md`](../../docs/ROUTING.md).

## Mandatory

- Each app builds its own router (`buildProviderRouter()` in
  [`apps/sanad_provider/lib/src/routing/provider_router.dart`](../../apps/sanad_provider/lib/src/routing/provider_router.dart);
  client equivalent under `apps/sanad_client/lib/src/routing/`).
- Feature routes are contributed by that feature's `FeatureModule.routes(...)`
  and aggregated via `moduleRegistry.allRoutes(routeContext)`. Do not hand-wire a
  feature's `GoRoute` list into the app router.
- Route paths are declared as constants in a feature `*_routes.dart` file
  (e.g. `OrganizationSettingsRoutes`, `AppRoutes`), never as inline string literals
  at call sites.
- Navigate with the `go_router` API (`context.push`/`context.go`/`context.pop`)
  and named path constants.
- Protected routes are declared through `FeatureRouteContext.protectedRoutes`
  and each feature's `*.protectedRoutes`; auth redirects are driven by
  `AuthStatusNotifier`.
- Provider RBAC gating goes through the `authorization` package and
  `provider_route_permissions.dart` / `provider_capabilities.dart` — gate routes
  there, not with ad-hoc checks in widgets.
- Bottom sheets / modals go through `SheetNavigator.push(context, widget, ...)`
  from [`packages/sheet_navigation/`](../../packages/sheet_navigation/), not
  `showModalBottomSheet` directly (see `edit_identity_bottom_sheet.dart` for
  the pattern: pop with a typed return value, `null` means dismissed without
  saving).

## Do Not

- Do not call `Navigator.of(context).push(MaterialPageRoute(...))` for
  app-level navigation between features. (Local, imperative `Navigator.pop`
  to return a value from a bottom sheet is fine.)
- Do not hardcode route path strings at call sites.
- Do not bypass RBAC route permissions for provider features.
- Do not call `showModalBottomSheet` directly for a feature bottom
  sheet/modal — use `SheetNavigator` so sheets share one presentation/routing
  convention.

## Preferred

- Prefer passing typed values via `state.extra` with a defensive type check and
  a sensible fallback (see `organization_settings_module.dart`).

## Validation

- Manual/route tests; no dedicated router-lint script.
