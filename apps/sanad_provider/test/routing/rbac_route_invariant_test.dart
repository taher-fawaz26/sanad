// RBAC Phase 7P — route-invariant golden test.
//
// Pins the following invariant: every entry point into the `provider_rbac`
// feature's route tree is owner-only-gated. If a future contributor adds a
// per-permission RBAC route (which would be a genuine backend-contract
// change — RBAC administration is owner-only in its entirety today, RBAC
// Phase 7 finding F1), this test fails, forcing a conscious update to the
// audit spec rather than a silent gate relaxation.

import 'package:auth/auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_rbac/provider_rbac.dart';
import 'package:sanad_provider/src/routing/app_routes.dart';
import 'package:sanad_provider/src/routing/provider_router.dart';

void main() {
  group('provider_rbac routes — Phase 7P invariant', () {
    /// Every distinct entry point into the RBAC feature tree that the
    /// audit's execution order (7E) declared owner-only. New routes go
    /// here; each is then asserted to redirect a team member home.
    final entryPoints = <String>[
      ProviderRbacRoutes.list,
      ProviderRbacRoutes.add,
      ProviderRbacRoutes.detailsFor('role-abc'),
      ProviderRbacRoutes.editFor('role-abc'),
    ];

    for (final location in entryPoints) {
      test(
        'a worker/manager holding provider:worker:view (would satisfy the '
        'permission guard if any) is still redirected home from $location '
        '— the owner-only guard covers the whole feature via '
        'ProviderRbacRoutes.isProtectedRoute',
        () {
          expect(
            resolveProviderRedirect(
              location: location,
              isAuthenticated: true,
              canManageOrganization: false,
              isOrganizationTeamMember: true,
            ),
            AppRoutes.home,
          );
        },
      );

      test(
        'an owner ($location) is allowed — the guard is persona-gated, '
        'not blanket-hidden. Regression check for the Phase-7E ordering '
        'where the org-only guard fires before the owner-only guard',
        () {
          expect(
            resolveProviderRedirect(
              location: location,
              isAuthenticated: true,
              canManageOrganization: true,
              isProviderOwner: true,
            ),
            isNull,
          );
        },
      );
    }

    test(
      'unauthenticated deep link into RBAC hits the auth guard first, '
      'not the owner-only guard — regression check that /login wins',
      () {
        for (final location in entryPoints) {
          expect(
            resolveProviderRedirect(
              location: location,
              isAuthenticated: false,
              canManageOrganization: false,
            ),
            AuthRoutes.login,
            reason: '$location must send unauthenticated users to /login',
          );
        }
      },
    );

    test(
      'every RBAC entry point is caught by ProviderRbacRoutes.isProtected'
      'Route — the predicate the router owner-only guard actually consults. '
      'If this diverges, a future contributor could add a route to '
      'ProviderRbacRoutes that IS registered elsewhere but NOT covered by '
      'the isProtectedRoute predicate, silently bypassing the guard.',
      () {
        for (final location in entryPoints) {
          expect(
            ProviderRbacRoutes.isProtectedRoute(location),
            isTrue,
            reason:
                '$location must be recognised by the predicate the '
                'router uses to enforce the owner-only guard',
          );
        }
      },
    );
  });
}
