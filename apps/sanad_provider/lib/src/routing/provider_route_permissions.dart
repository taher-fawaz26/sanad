import 'package:authorization/authorization.dart';
import 'package:branches/branches.dart';
import 'package:sanad_provider/src/routing/app_routes.dart';
import 'package:services/services.dart';
import 'package:workers/workers.dart';

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

      // Services — RBAC Phase 7E. The owner-only sub-surfaces (add,
      // request-new, a request detail, editing a service) are gated
      // separately, by persona, in resolveProviderRedirect's owner-only
      // guard (see ServiceRoutes.isOwnerOnlyRoute) — no permission exists
      // for any of those writes (finding G3). Only the read surfaces below
      // are gated here.
      const RouteRule.exact(
        {ServiceRoutes.list},
        requires: PermissionRequirement.single(
          ServicePermissions.providerServiceView,
        ),
      ),
      // A service detail is nested under /services/:id, which also matches
      // /services/add and /services/request-new — both already resolved by
      // the owner-only guard before this table is ever consulted, so no
      // rule-ordering hazard exists here the way it does for Branches.
      RouteRule.pattern(
        RegExp(r'^/services/[^/]+$'),
        requires: const PermissionRequirement.single(
          ServicePermissions.providerServiceView,
        ),
      ),

      // Workers — RBAC Phase 7E. Inviting/editing a worker is gated
      // separately, by persona (see WorkerRoutes.isOwnerOnlyRoute) — no
      // permission exists for either write.
      const RouteRule.exact(
        {WorkerRoutes.list},
        requires: PermissionRequirement.single(WorkerPermissions.view),
      ),
      // /workers/add is a single path segment too, so it also matches this
      // pattern — same shadowing shape as Branches, resolved the same way:
      // the owner-only guard already redirects a non-owner away from
      // /workers/add before this table is ever consulted, and an owner
      // trivially satisfies WorkerPermissions.view via provider:*.
      RouteRule.pattern(
        RegExp(r'^/workers/[^/]+$'),
        requires: const PermissionRequirement.single(WorkerPermissions.view),
      ),
    ]);
