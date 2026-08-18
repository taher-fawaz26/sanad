// RBAC Phase 7S — runtime permission-revocation widget test.
//
// A worker holding `worker:view` is at `/workers`. A `PermissionSet` update
// mid-session drops the permission. Assert:
//   1. The router's redirect re-runs (the merged `refreshListenable` fires).
//   2. The next resolve for `/workers` returns `AppRoutes.home` — so a
//      user who was ON that page gets bounced out.
//   3. Analogous check for a service list view.
//
// This exercises the exact revocation path the audit's Definition of Done
// requires — a role change lands via `/me`, `AuthorizationSignal` notifies,
// GoRouter's `refreshListenable` re-runs the redirect, and any currently
// unauthorized location resolves to the home fallback.

import 'package:authorization/authorization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_provider/src/routing/app_routes.dart';
import 'package:sanad_provider/src/routing/provider_route_permissions.dart';
import 'package:sanad_provider/src/routing/provider_router.dart';
import 'package:services/services.dart';
import 'package:workers/workers.dart';

/// A test-local `AuthorizationReader` we can drive imperatively. Mirrors
/// `AuthorizationSignal`'s public shape — no need to depend on `packages/
/// auth`'s internals here.
class _MutablePermissions extends ChangeNotifier
    implements AuthorizationReader {
  _MutablePermissions(Iterable<String> initial)
    : _permissions = PermissionSet.from(initial);

  PermissionSet _permissions;

  @override
  PermissionSet get permissions => _permissions;

  @override
  bool get isResolved => true;

  void revoke(Iterable<String> keep) {
    _permissions = PermissionSet.from(keep);
    notifyListeners();
  }

  @override
  bool can(String action) => _permissions.can(action);

  @override
  bool canAny(Iterable<String> actions) => _permissions.canAny(actions);

  @override
  bool canAll(Iterable<String> actions) => _permissions.canAll(actions);

  @override
  bool satisfies(PermissionRequirement requirement) =>
      requirement.isSatisfiedBy(_permissions);
}

/// Mirrors `resolveProviderRedirect`'s worker-scenario call signature —
/// same defaults `buildProviderRouter` uses.
String? _resolveForWorker(
  String location, {
  required AuthorizationReader reader,
}) => resolveProviderRedirect(
  location: location,
  isAuthenticated: true,
  canManageOrganization: false,
  isProviderOwner: false,
  isOrganizationTeamMember: true,
  permissions: reader.permissions,
  permissionsResolved: reader.isResolved,
  table: providerRoutePermissions,
);

void main() {
  group('runtime permission revocation (RBAC Phase 7S)', () {
    testWidgets(
      'a mid-session revocation of worker:view redirects an active '
      '/workers session home — the refreshListenable re-fires, the '
      'router re-evaluates, and the location the user is on becomes '
      'unauthorized',
      (tester) async {
        final authStatus = ChangeNotifier();
        final permissions = _MutablePermissions([WorkerPermissions.view]);

        // Before revocation: /workers resolves as allowed.
        expect(
          _resolveForWorker(WorkerRoutes.list, reader: permissions),
          isNull,
        );

        var redirectCalls = 0;
        final router = GoRouter(
          initialLocation: WorkerRoutes.list,
          refreshListenable: Listenable.merge([authStatus, permissions]),
          redirect: (context, state) {
            redirectCalls++;
            return _resolveForWorker(
              state.matchedLocation,
              reader: permissions,
            );
          },
          routes: [
            GoRoute(
              path: WorkerRoutes.list,
              builder: (_, _) => const Scaffold(body: Text('workers-page')),
            ),
            GoRoute(
              path: AppRoutes.home,
              builder: (_, _) => const Scaffold(body: Text('home-page')),
            ),
          ],
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        expect(find.text('workers-page'), findsOneWidget);
        final callsBeforeRevoke = redirectCalls;

        // Revoke.
        permissions.revoke(const []);
        await tester.pumpAndSettle();

        // Redirect fired again (the merged listenable ticked).
        expect(redirectCalls, greaterThan(callsBeforeRevoke));

        // /workers resolves to /home post-revocation.
        expect(
          _resolveForWorker(WorkerRoutes.list, reader: permissions),
          AppRoutes.home,
        );

        // The user is now on /home, not /workers.
        expect(find.text('home-page'), findsOneWidget);
        expect(find.text('workers-page'), findsNothing);
      },
    );

    testWidgets(
      'the Services list survives an UNRELATED revocation — dropping '
      'worker:view does not affect provider-service:view. Regression '
      'check that the router only responds to changes affecting the '
      'CURRENT location, not blanket-redirects on any listenable tick.',
      (tester) async {
        final authStatus = ChangeNotifier();
        final permissions = _MutablePermissions([
          WorkerPermissions.view,
          ServicePermissions.providerServiceView,
        ]);

        final router = GoRouter(
          initialLocation: ServiceRoutes.list,
          refreshListenable: Listenable.merge([authStatus, permissions]),
          redirect: (context, state) =>
              _resolveForWorker(state.matchedLocation, reader: permissions),
          routes: [
            GoRoute(
              path: ServiceRoutes.list,
              builder: (_, _) => const Scaffold(body: Text('services-page')),
            ),
            GoRoute(
              path: AppRoutes.home,
              builder: (_, _) => const Scaffold(body: Text('home-page')),
            ),
          ],
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        expect(find.text('services-page'), findsOneWidget);

        // Drop worker:view but keep provider-service:view.
        permissions.revoke(const [ServicePermissions.providerServiceView]);
        await tester.pumpAndSettle();

        // Still on services-page — the change didn't affect this location.
        expect(find.text('services-page'), findsOneWidget);
        expect(find.text('home-page'), findsNothing);
      },
    );
  });
}
