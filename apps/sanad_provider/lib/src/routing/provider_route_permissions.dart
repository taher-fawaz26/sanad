import 'package:authorization/authorization.dart';
import 'package:branches/branches.dart';
import 'package:sanad_provider/src/routing/app_routes.dart';

/// The provider app's declarative route → permission-requirement table,
/// consumed by `resolveProviderRedirect`. Deliberately kept in the app (not
/// a shared package) — same reasoning as `ProviderCapabilities`: which
/// routes require which backend permission is a Provider-app routing
/// concern. The permission *identity strings* themselves stay feature-owned
/// (e.g. `BranchPermissions`, exported by `package:branches`) so a feature
/// package never needs to depend on the app to reference its own actions.
///
/// **Rule order is load-bearing — most specific first.** `BranchRoutes`'
/// details pattern (`^/branches/[^/]+$`) also matches `/branches/add` and
/// `/branches/coverage`, so those literal paths are registered ahead of it.
/// [RouteAuthorizationTable] is first-match-wins.
///
/// Not `const` — a [RouteRule.pattern] entry holds a [RegExp], which Dart
/// cannot construct as a compile-time constant.
///
/// Populated feature-by-feature as each is migrated — Branches first (see
/// the RBAC migration plan) — so real user-facing gating grows deliberately
/// rather than all at once.
final RouteAuthorizationTable providerRoutePermissions =
    RouteAuthorizationTable([
      // denyRedirect targets AppRoutes.home, not BranchRoutes.list: /branches
      // itself requires branchView, and a role holding create/update without
      // view (unusual, but not precluded by the backend model) would
      // otherwise bounce through /branches before landing on /home anyway —
      // violating the "every denial target is requirement-free" invariant
      // this table is tested against.
      const RouteRule.exact(
        {BranchRoutes.add},
        requires: PermissionRequirement.single(BranchPermissions.create),
        denyRedirect: AppRoutes.home,
      ),
      // Shared by both the add-branch wizard and the details-page edit flow
      // — neither single permission alone is correct for it.
      const RouteRule.exact(
        {BranchRoutes.coverage},
        requires: PermissionRequirement.any({
          BranchPermissions.create,
          BranchPermissions.update,
        }),
        denyRedirect: AppRoutes.home,
      ),
      const RouteRule.exact(
        {BranchRoutes.list},
        requires: PermissionRequirement.single(BranchPermissions.view),
      ),
      // Mirrors BranchRoutes' own details-route matcher — kept local rather
      // than reusing BranchRoutes.isProtectedRoute (which also matches
      // /add and /coverage, exactly the shadowing this ordering avoids).
      RouteRule.pattern(
        RegExp(r'^/branches/[^/]+$'),
        requires: const PermissionRequirement.single(BranchPermissions.view),
      ),
    ]);
