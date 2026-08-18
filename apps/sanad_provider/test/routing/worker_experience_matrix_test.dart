// RBAC Phase 7R — worker-experience regression matrix.
//
// One test file, three real-world worker scenarios. Each pumps
// `resolveProviderRedirect` through every user-visible route and asserts:
//   • the expected allow/deny outcome per route, and
//   • that the specific bug class the phase closed (unauthorized fetch,
//     reveal-then-bounce, org-only-guard mis-fire) cannot recur.
//
// The three scenarios come from the audit spec (§8.5). They are the widest
// coverage the pure-function router API allows without pumping a full app
// tree — which is what Phase 7S covers separately for the mid-session
// revocation case.

import 'package:account_settings/account_settings.dart';
import 'package:authorization/authorization.dart';
import 'package:branches/branches.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_rbac/provider_rbac.dart';
import 'package:sanad_provider/src/features/organization_settings/organization_settings.dart';
import 'package:sanad_provider/src/routing/app_routes.dart';
import 'package:sanad_provider/src/routing/provider_route_permissions.dart';
import 'package:sanad_provider/src/routing/provider_router.dart';
import 'package:services/services.dart';
import 'package:workers/workers.dart';

/// Common helper — every scenario resolves the same way except for the
/// permission set and the persona flags. Threads the exact call-site
/// arguments `buildProviderRouter` uses at runtime.
String? _resolve(
  String location, {
  required Iterable<String> permissions,
  required bool isProviderOwner,
  required bool isOrganizationTeamMember,
}) => resolveProviderRedirect(
  location: location,
  isAuthenticated: true,
  canManageOrganization: false,
  isProviderOwner: isProviderOwner,
  isOrganizationTeamMember: isOrganizationTeamMember,
  permissions: PermissionSet.from(permissions),
  permissionsResolved: true,
  table: providerRoutePermissions,
  ownerOnlyRoutes: const {OrganizationSettingsRoutes.legalDocuments},
);

void main() {
  group('Scenario A — worker with {branch:view, catalog-service:view, '
      'provider-service:view} (the exact reporter permission set)', () {
    const perms = [
      BranchPermissions.view,
      ServicePermissions.catalogView,
      ServicePermissions.providerServiceView,
      WorkerPermissions.view,
    ];

    test('Home is reachable', () {
      expect(
        _resolve(
          AppRoutes.home,
          permissions: perms,
          isProviderOwner: false,
          isOrganizationTeamMember: true,
        ),
        isNull,
      );
    });

    test('Services list AND a service detail both reachable', () {
      for (final loc in [ServiceRoutes.list, ServiceRoutes.detailsFor('s1')]) {
        expect(
          _resolve(
            loc,
            permissions: perms,
            isProviderOwner: false,
            isOrganizationTeamMember: true,
          ),
          isNull,
          reason: '$loc must be reachable with provider-service:view',
        );
      }
    });

    test(
      'every owner-only Services sub-surface is denied home — Add / '
      'Request-new / a request detail / Edit',
      () {
        for (final loc in [
          ServiceRoutes.add,
          ServiceRoutes.requestNew,
          ServiceRoutes.requestDetailsFor('r1'),
          ServiceRoutes.editFor('s1'),
        ]) {
          expect(
            _resolve(
              loc,
              permissions: perms,
              isProviderOwner: false,
              isOrganizationTeamMember: true,
            ),
            AppRoutes.home,
            reason: '$loc is owner-only — worker must be redirected home',
          );
        }
      },
    );

    test('Branches (list + a detail) reachable, Add + Coverage denied', () {
      expect(
        _resolve(
          BranchRoutes.list,
          permissions: perms,
          isProviderOwner: false,
          isOrganizationTeamMember: true,
        ),
        isNull,
      );
      expect(
        _resolve(
          BranchRoutes.detailsFor('b1'),
          permissions: perms,
          isProviderOwner: false,
          isOrganizationTeamMember: true,
        ),
        isNull,
      );
      expect(
        _resolve(
          BranchRoutes.add,
          permissions: perms,
          isProviderOwner: false,
          isOrganizationTeamMember: true,
        ),
        AppRoutes.home,
      );
      expect(
        _resolve(
          BranchRoutes.coverage,
          permissions: perms,
          isProviderOwner: false,
          isOrganizationTeamMember: true,
        ),
        AppRoutes.home,
      );
    });

    test(
      'Workers list is reachable (worker:view held); invite + edit denied',
      () {
        expect(
          _resolve(
            WorkerRoutes.list,
            permissions: perms,
            isProviderOwner: false,
            isOrganizationTeamMember: true,
          ),
          isNull,
        );
        expect(
          _resolve(
            WorkerRoutes.add,
            permissions: perms,
            isProviderOwner: false,
            isOrganizationTeamMember: true,
          ),
          AppRoutes.home,
        );
        expect(
          _resolve(
            WorkerRoutes.editWorkerFor('w1'),
            permissions: perms,
            isProviderOwner: false,
            isOrganizationTeamMember: true,
          ),
          AppRoutes.home,
        );
      },
    );

    test(
      'every RBAC entry point is redirected home — feature is owner-only',
      () {
        for (final loc in [
          ProviderRbacRoutes.list,
          ProviderRbacRoutes.add,
          ProviderRbacRoutes.detailsFor('r1'),
          ProviderRbacRoutes.editFor('r1'),
        ]) {
          expect(
            _resolve(
              loc,
              permissions: perms,
              isProviderOwner: false,
              isOrganizationTeamMember: true,
            ),
            AppRoutes.home,
            reason: '$loc is owner-only',
          );
        }
      },
    );

    test(
      'Settings tab goes to Account Settings — the reported /settings + '
      '/service-provider/legal-data 403 chain never fires because the '
      'router redirects the non-owner off /settings first (RBAC Phase 7K)',
      () {
        expect(
          _resolve(
            OrganizationSettingsRoutes.hub,
            permissions: perms,
            isProviderOwner: false,
            isOrganizationTeamMember: true,
          ),
          AccountSettingsRoutes.hub,
        );
      },
    );

    test(
      'legal-documents is unreachable — the owner-only ownerOnlyRoutes '
      'entry catches it too (RBAC Phase 7G defense-in-depth)',
      () {
        expect(
          _resolve(
            OrganizationSettingsRoutes.legalDocuments,
            permissions: perms,
            isProviderOwner: false,
            isOrganizationTeamMember: true,
          ),
          AppRoutes.home,
        );
      },
    );
  });

  group('Scenario B — worker with {branch:view, branch:update}', () {
    const perms = [BranchPermissions.view, BranchPermissions.update];

    test(
      'Branches list AND details AND coverage (edit flow) all reachable',
      () {
        for (final loc in [
          BranchRoutes.list,
          BranchRoutes.detailsFor('b1'),
          BranchRoutes.coverage,
        ]) {
          expect(
            _resolve(
              loc,
              permissions: perms,
              isProviderOwner: false,
              isOrganizationTeamMember: true,
            ),
            isNull,
            reason: '$loc must be reachable with view + update',
          );
        }
      },
    );

    test(
      'Add Branch is denied — no branch:create held',
      () {
        expect(
          _resolve(
            BranchRoutes.add,
            permissions: perms,
            isProviderOwner: false,
            isOrganizationTeamMember: true,
          ),
          AppRoutes.home,
        );
      },
    );

    test(
      'Services list is denied — no provider-service:view held; '
      'proves the permission guard actually denies when the user lacks '
      'the required action (not just when they lack all permissions)',
      () {
        expect(
          _resolve(
            ServiceRoutes.list,
            permissions: perms,
            isProviderOwner: false,
            isOrganizationTeamMember: true,
          ),
          AppRoutes.home,
        );
      },
    );
  });

  group('Scenario C — empty, resolved permission set', () {
    test(
      'every permission-gated route is denied home; auth-only routes '
      '(Home) still reachable',
      () {
        // Home has no permission requirement — reachable.
        expect(
          _resolve(
            AppRoutes.home,
            permissions: const [],
            isProviderOwner: false,
            isOrganizationTeamMember: true,
          ),
          isNull,
        );

        // Every permission-gated route denies.
        for (final loc in [
          BranchRoutes.list,
          BranchRoutes.detailsFor('b1'),
          ServiceRoutes.list,
          ServiceRoutes.detailsFor('s1'),
          WorkerRoutes.list,
          WorkerRoutes.detailsFor('w1'),
        ]) {
          expect(
            _resolve(
              loc,
              permissions: const [],
              isProviderOwner: false,
              isOrganizationTeamMember: true,
            ),
            AppRoutes.home,
            reason: '$loc must be denied with no permissions',
          );
        }
      },
    );

    test(
      'Account Settings stays reachable — it is auth-only, not '
      'permission-gated, and serves all four provider personas',
      () {
        expect(
          _resolve(
            AccountSettingsRoutes.hub,
            permissions: const [],
            isProviderOwner: false,
            isOrganizationTeamMember: true,
          ),
          isNull,
        );
      },
    );
  });
}
