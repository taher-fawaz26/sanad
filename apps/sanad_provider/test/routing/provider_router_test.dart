import 'package:account_settings/account_settings.dart';
import 'package:auth/auth.dart';
import 'package:authorization/authorization.dart';
import 'package:branches/branches.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider_rbac/provider_rbac.dart';
import 'package:sanad_provider/src/features/organization_settings/organization_settings.dart';
import 'package:sanad_provider/src/routing/app_routes.dart';
import 'package:sanad_provider/src/routing/provider_route_permissions.dart';
import 'package:sanad_provider/src/routing/provider_router.dart';
import 'package:services/services.dart';
import 'package:workers/workers.dart';

void main() {
  group('buildSettingsTabPage — persona-aware Settings tab', () {
    test('organization providers get the KPI/setup hub', () {
      final page = buildSettingsTabPage(canManageOrganization: true);
      expect(page, isA<OrganizationSettingsPage>());
    });

    test('individual providers get General Settings mounted as a root tab '
        '(no back affordance to pop)', () {
      final page = buildSettingsTabPage(canManageOrganization: false);
      expect(page, isA<GeneralSettingsPage>());
      expect((page as GeneralSettingsPage).isRootTab, isTrue);
    });

    test('the organization hub is never a root tab — General Settings stays a '
        'pushed child there', () {
      final page = buildSettingsTabPage(canManageOrganization: true);
      // Sanity: the org path is a different page type, not GeneralSettingsPage.
      expect(page, isNot(isA<GeneralSettingsPage>()));
    });
  });

  group('resolveProviderRedirect — auth guard', () {
    test('unauthenticated access to a protected route redirects to login', () {
      expect(
        resolveProviderRedirect(
          location: '/home',
          isAuthenticated: false,
          canManageOrganization: false,
        ),
        AuthRoutes.login,
      );
    });

    test('authenticated access to a protected route is not redirected', () {
      expect(
        resolveProviderRedirect(
          location: '/home',
          isAuthenticated: true,
          canManageOrganization: false,
        ),
        isNull,
      );
    });

    test('add/request-new Services routes are auth-protected', () {
      for (final location in [
        ServiceRoutes.list,
        ServiceRoutes.add,
        ServiceRoutes.requestNew,
      ]) {
        expect(
          resolveProviderRedirect(
            location: location,
            isAuthenticated: false,
            canManageOrganization: false,
          ),
          AuthRoutes.login,
          reason: '$location must require authentication',
        );
      }
    });

    test('Roles & Permissions routes are auth-protected', () {
      for (final location in [
        ProviderRbacRoutes.list,
        ProviderRbacRoutes.add,
      ]) {
        expect(
          resolveProviderRedirect(
            location: location,
            isAuthenticated: false,
            canManageOrganization: true,
          ),
          AuthRoutes.login,
          reason: '$location must require authentication',
        );
      }
    });
  });

  group('resolveProviderRedirect — organization-only guard', () {
    const orgOnlyRoutes = [
      BranchRoutes.list,
      BranchRoutes.add,
      BranchRoutes.coverage,
      WorkerRoutes.list,
      ProviderRbacRoutes.list,
      ProviderRbacRoutes.add,
    ];

    for (final location in orgOnlyRoutes) {
      test('individual provider hitting $location is redirected to the '
          'Settings tab', () {
        expect(
          resolveProviderRedirect(
            location: location,
            isAuthenticated: true,
            canManageOrganization: false,
          ),
          // The shell Settings tab — its builder renders General Settings for
          // individuals, keeping the bottom nav visible. NOT the full-screen
          // `/settings/general` child, which has no parent to pop back to.
          OrganizationSettingsRoutes.hub,
        );
      });
    }

    // Branches and the Workers list are permission-gated, not owner-only —
    // a genuine org member who isn't the owner (a worker/manager) must still
    // reach them once past this guard, provided they hold the real
    // permission (asserted separately by the Branches/Services/Workers
    // real-rules test groups below; here isProviderOwner is irrelevant —
    // that's the point).
    const permissionGatedOrgOnlyRoutes = [
      BranchRoutes.list,
      BranchRoutes.add,
      BranchRoutes.coverage,
      WorkerRoutes.list,
    ];

    for (final location in permissionGatedOrgOnlyRoutes) {
      test('organization provider can access $location', () {
        expect(
          resolveProviderRedirect(
            location: location,
            isAuthenticated: true,
            canManageOrganization: true,
          ),
          isNull,
        );
      });

      test(
        'a worker/manager team member reaches $location too (RBAC Phase '
        '7E fix — this route is permission-gated, not owner-only, so a '
        'team member must fall through to the permission guard rather '
        'than be redirected on persona alone)',
        () {
          expect(
            resolveProviderRedirect(
              location: location,
              isAuthenticated: true,
              canManageOrganization: false,
              isOrganizationTeamMember: true,
            ),
            isNull,
          );
        },
      );
    }

    // Provider RBAC is org-only AND owner-only in its entirety (finding F1
    // — administration is never delegable) — unlike Branches/Workers above,
    // a team member must NOT reach it even after clearing this guard; only
    // the owner-only guard's own tests (and the dedicated RBAC group in
    // Phase 7H) assert that half.
    const rbacRoutes = [ProviderRbacRoutes.list, ProviderRbacRoutes.add];

    for (final location in rbacRoutes) {
      test('organization owner can access $location', () {
        expect(
          resolveProviderRedirect(
            location: location,
            isAuthenticated: true,
            canManageOrganization: true,
            isProviderOwner: true,
          ),
          isNull,
        );
      });

      test(
        'a worker/manager team member clears this guard but is still '
        'redirected home by the owner-only guard for $location',
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
    }

    test(
      'an individual provider (neither the owner nor a team member) is '
      'still redirected — isOrganizationTeamMember does not widen access '
      'beyond actual organization membership',
      () {
        expect(
          resolveProviderRedirect(
            location: BranchRoutes.list,
            isAuthenticated: true,
            canManageOrganization: false,
          ),
          OrganizationSettingsRoutes.hub,
        );
      },
    );

    test('individual provider is NOT redirected away from the Settings tab '
        '(its builder renders General Settings for them)', () {
      expect(
        resolveProviderRedirect(
          location: OrganizationSettingsRoutes.hub,
          isAuthenticated: true,
          canManageOrganization: false,
          // Every individual provider IS the owner (see Services test
          // below for the same rationale) — required after RBAC Phase 7K,
          // when non-owners hitting /settings are redirected to Account
          // Settings.
          isProviderOwner: true,
        ),
        isNull,
      );
    });

    test('organization provider can access the Settings hub', () {
      expect(
        resolveProviderRedirect(
          location: OrganizationSettingsRoutes.hub,
          isAuthenticated: true,
          canManageOrganization: true,
          isProviderOwner: true,
        ),
        isNull,
      );
    });

    test(
      'a worker/manager team member hitting /settings directly is '
      'redirected to /settings/account (RBAC Phase 7K) — General Settings '
      'is owner-only in practice; workers only ever see Account Settings',
      () {
        expect(
          resolveProviderRedirect(
            location: OrganizationSettingsRoutes.hub,
            isAuthenticated: true,
            canManageOrganization: false,
            isOrganizationTeamMember: true,
          ),
          AccountSettingsRoutes.hub,
        );
      },
    );

    test(
      'unauthenticated wins over the Settings persona redirect — auth guard '
      'takes precedence, so a non-owner hitting /settings while logged out '
      'goes to /login, not /settings/account',
      () {
        expect(
          resolveProviderRedirect(
            location: OrganizationSettingsRoutes.hub,
            isAuthenticated: false,
            canManageOrganization: false,
          ),
          AuthRoutes.login,
        );
      },
    );

    test('individual provider CAN access Services', () {
      for (final location in [
        ServiceRoutes.list,
        ServiceRoutes.add,
        ServiceRoutes.requestNew,
      ]) {
        expect(
          resolveProviderRedirect(
            location: location,
            isAuthenticated: true,
            canManageOrganization: false,
            // Every individual provider IS the owner — there is no such
            // thing as a non-owner individual-provider account (only an
            // organization can have workers/managers) — so this is the
            // accurate persona for add/request-new, which are owner-only
            // sub-surfaces as of RBAC Phase 7E (finding G3).
            isProviderOwner: true,
          ),
          isNull,
          reason: 'Services is not organization-only',
        );
      }
    });

    test('individual provider CAN access General Settings directly', () {
      expect(
        resolveProviderRedirect(
          location: OrganizationSettingsRoutes.general,
          isAuthenticated: true,
          canManageOrganization: false,
        ),
        isNull,
      );
    });

    test('individual provider CAN access the legal-documents update flow', () {
      expect(
        resolveProviderRedirect(
          location: OrganizationSettingsRoutes.legalDocuments,
          isAuthenticated: true,
          canManageOrganization: false,
        ),
        isNull,
      );
    });

    test('unauthenticated access to an org-only route redirects to login, '
        'not General Settings', () {
      expect(
        resolveProviderRedirect(
          location: BranchRoutes.list,
          isAuthenticated: false,
          canManageOrganization: false,
        ),
        AuthRoutes.login,
      );
    });

    test('a branch detail deep link is org-only', () {
      expect(
        resolveProviderRedirect(
          location: BranchRoutes.detailsFor('b1'),
          isAuthenticated: true,
          canManageOrganization: false,
        ),
        OrganizationSettingsRoutes.hub,
      );
    });

    test('a worker/invitation deep link under /workers/ is org-only', () {
      expect(
        resolveProviderRedirect(
          location: '/workers/w1',
          isAuthenticated: true,
          canManageOrganization: false,
        ),
        OrganizationSettingsRoutes.hub,
      );
    });

    test('a roles-permissions deep link is org-only', () {
      expect(
        resolveProviderRedirect(
          location: ProviderRbacRoutes.editFor('r1'),
          isAuthenticated: true,
          canManageOrganization: false,
        ),
        OrganizationSettingsRoutes.hub,
      );
    });
  });

  group('resolveProviderRedirect — owner-only guard', () {
    const ownerOnlyRoutes = {'/owner-surface'};

    test('a provider owner (individual or organization) is allowed', () {
      expect(
        resolveProviderRedirect(
          location: '/owner-surface',
          isAuthenticated: true,
          canManageOrganization: false,
          isProviderOwner: true,
          ownerOnlyRoutes: ownerOnlyRoutes,
        ),
        isNull,
      );
    });

    test(
      'a manager/worker is redirected home, regardless of granted permissions',
      () {
        expect(
          resolveProviderRedirect(
            location: '/owner-surface',
            isAuthenticated: true,
            canManageOrganization: false,
            ownerOnlyRoutes: ownerOnlyRoutes,
          ),
          AppRoutes.home,
        );
      },
    );

    test('unauthenticated wins over the owner-only guard', () {
      // /home is a genuinely auth-protected route (AppRoutes.protected); see
      // the equivalent note in the permission-guard group above.
      expect(
        resolveProviderRedirect(
          location: '/home',
          isAuthenticated: false,
          canManageOrganization: false,
          ownerOnlyRoutes: const {'/home'},
        ),
        AuthRoutes.login,
      );
    });

    test('an unregistered location is unaffected by a non-empty set', () {
      expect(
        resolveProviderRedirect(
          location: '/home',
          isAuthenticated: true,
          canManageOrganization: false,
          ownerOnlyRoutes: ownerOnlyRoutes,
        ),
        isNull,
      );
    });

    test(
      'defaults to empty — an unregistered location is unaffected when the '
      'caller passes nothing',
      () {
        expect(
          resolveProviderRedirect(
            location: '/owner-surface',
            isAuthenticated: true,
            canManageOrganization: false,
          ),
          isNull,
          reason:
              'ownerOnlyRoutes defaults to empty for this synthetic test '
              'location — the real call site in provider_router.dart '
              'populates it (see the legal-documents test below)',
        );
      },
    );

    test(
      'the real call site gates legal-documents as owner-only (RBAC Phase '
      '7G) — backed by service-provider/legal-data, which 403s for a '
      'worker/manager regardless of granted permissions',
      () {
        expect(
          resolveProviderRedirect(
            location: OrganizationSettingsRoutes.legalDocuments,
            isAuthenticated: true,
            canManageOrganization: false,
            ownerOnlyRoutes: const {OrganizationSettingsRoutes.legalDocuments},
          ),
          AppRoutes.home,
        );

        expect(
          resolveProviderRedirect(
            location: OrganizationSettingsRoutes.legalDocuments,
            isAuthenticated: true,
            canManageOrganization: false,
            isProviderOwner: true,
            ownerOnlyRoutes: const {OrganizationSettingsRoutes.legalDocuments},
          ),
          isNull,
        );
      },
    );
  });

  group('resolveProviderRedirect — permission guard', () {
    const view = PermissionRequirement.single('provider:branch:view');
    const table = RouteAuthorizationTable([
      RouteRule.exact(
        {'/gated'},
        requires: view,
        denyRedirect: '/denied-here',
      ),
      RouteRule.exact({'/gated-no-redirect'}, requires: view),
    ]);

    test('allows a resolved, granted permission', () {
      expect(
        resolveProviderRedirect(
          location: '/gated',
          isAuthenticated: true,
          canManageOrganization: false,
          permissions: PermissionSet.from(const ['provider:branch:view']),
          permissionsResolved: true,
          table: table,
        ),
        isNull,
      );
    });

    test(
      "redirects to the rule's denyRedirect on a resolved, denied permission",
      () {
        expect(
          resolveProviderRedirect(
            location: '/gated',
            isAuthenticated: true,
            canManageOrganization: false,
            permissionsResolved: true,
            table: table,
          ),
          '/denied-here',
        );
      },
    );

    test('falls back to AppRoutes.home when the rule has no denyRedirect', () {
      expect(
        resolveProviderRedirect(
          location: '/gated-no-redirect',
          isAuthenticated: true,
          canManageOrganization: false,
          permissionsResolved: true,
          table: table,
        ),
        AppRoutes.home,
      );
    });

    test(
      'fails OPEN (allows) when permissions are unresolved, even for a route '
      'the permission set would otherwise deny',
      () {
        expect(
          resolveProviderRedirect(
            location: '/gated',
            isAuthenticated: true,
            canManageOrganization: false,
            table: table,
          ),
          isNull,
          reason:
              'permissionsResolved defaults to false — a deep link or '
              'just-restored cold start must never be bounced on a timing '
              'artifact (see PermissionResync)',
        );
      },
    );

    test('unauthenticated wins over the permission guard', () {
      // /home is a genuinely auth-protected route (AppRoutes.protected), so
      // this exercises the real precedence: the auth guard must redirect to
      // /login before the permission guard is ever consulted — even for a
      // resolved, denying table entry gating the same location.
      const homeGatedTable = RouteAuthorizationTable([
        RouteRule.exact({'/home'}, requires: view),
      ]);

      expect(
        resolveProviderRedirect(
          location: '/home',
          isAuthenticated: false,
          canManageOrganization: false,
          permissionsResolved: true,
          table: homeGatedTable,
        ),
        AuthRoutes.login,
      );
    });

    test('an unmatched location is unaffected by a non-empty table', () {
      expect(
        resolveProviderRedirect(
          location: '/home',
          isAuthenticated: true,
          canManageOrganization: false,
          permissionsResolved: true,
          table: table,
        ),
        isNull,
      );
    });

    test(
      'a team member who clears the org-only guard is still denied by the '
      'permission guard when they lack the real permission (RBAC Phase 7E '
      '— isOrganizationTeamMember is not a blanket bypass, it only lets a '
      'team member reach this guard instead of being stopped earlier)',
      () {
        const branchGatedTable = RouteAuthorizationTable([
          RouteRule.exact({BranchRoutes.list}, requires: view),
        ]);

        expect(
          resolveProviderRedirect(
            location: BranchRoutes.list,
            isAuthenticated: true,
            canManageOrganization: false,
            isOrganizationTeamMember: true,
            permissionsResolved: true,
            table: branchGatedTable,
          ),
          AppRoutes.home,
        );
      },
    );

    test(
      'is pure and idempotent — repeat calls with identical inputs agree',
      () {
        final first = resolveProviderRedirect(
          location: '/gated',
          isAuthenticated: true,
          canManageOrganization: false,
          permissionsResolved: true,
          table: table,
        );
        final second = resolveProviderRedirect(
          location: '/gated',
          isAuthenticated: true,
          canManageOrganization: false,
          permissionsResolved: true,
          table: table,
        );
        expect(first, second);
      },
    );

    test(
      "empty table (today's real providerRoutePermissions) never redirects, "
      'regardless of permissions',
      () {
        expect(
          resolveProviderRedirect(
            location: '/gated',
            isAuthenticated: true,
            canManageOrganization: false,
            permissionsResolved: true,
          ),
          isNull,
        );
      },
    );
  });

  group('providerRoutePermissions — real Branches rules', () {
    String? redirectFor(String location, Iterable<String> granted) {
      return resolveProviderRedirect(
        location: location,
        isAuthenticated: true,
        canManageOrganization: true,
        permissions: PermissionSet.from(granted),
        permissionsResolved: true,
        table: providerRoutePermissions,
      );
    }

    test(
      "/branches/add resolves to branchCreate, not the details pattern's "
      'branchView — the rule-ordering hazard this table exists to avoid',
      () {
        expect(redirectFor(BranchRoutes.add, []), AppRoutes.home);
        expect(
          redirectFor(BranchRoutes.add, [BranchPermissions.view]),
          AppRoutes.home,
          reason: 'view alone must NOT satisfy the add route',
        );
        expect(
          redirectFor(BranchRoutes.add, [BranchPermissions.create]),
          isNull,
        );
      },
    );

    test('view-only: list and details allowed, add and coverage denied', () {
      final granted = [BranchPermissions.view];
      expect(redirectFor(BranchRoutes.list, granted), isNull);
      expect(redirectFor(BranchRoutes.detailsFor('b1'), granted), isNull);
      expect(redirectFor(BranchRoutes.add, granted), AppRoutes.home);
      expect(redirectFor(BranchRoutes.coverage, granted), AppRoutes.home);
    });

    test('view + create: add and coverage allowed alongside list/details', () {
      final granted = [BranchPermissions.view, BranchPermissions.create];
      expect(redirectFor(BranchRoutes.list, granted), isNull);
      expect(redirectFor(BranchRoutes.add, granted), isNull);
      expect(redirectFor(BranchRoutes.coverage, granted), isNull);
    });

    test('view + update: coverage allowed (edit flow), add still denied', () {
      final granted = [BranchPermissions.view, BranchPermissions.update];
      expect(redirectFor(BranchRoutes.list, granted), isNull);
      expect(redirectFor(BranchRoutes.coverage, granted), isNull);
      expect(redirectFor(BranchRoutes.add, granted), AppRoutes.home);
    });

    test('view + create + update: every Branches route is allowed', () {
      final granted = [
        BranchPermissions.view,
        BranchPermissions.create,
        BranchPermissions.update,
      ];
      for (final location in [
        BranchRoutes.list,
        BranchRoutes.add,
        BranchRoutes.coverage,
        BranchRoutes.detailsFor('b1'),
      ]) {
        expect(redirectFor(location, granted), isNull);
      }
    });

    test('provider:* (organization owner) is allowed everywhere', () {
      const granted = ['provider:*'];
      for (final location in [
        BranchRoutes.list,
        BranchRoutes.add,
        BranchRoutes.coverage,
        BranchRoutes.detailsFor('b1'),
      ]) {
        expect(redirectFor(location, granted), isNull);
      }
    });

    test('empty (resolved) permission set denies every Branches route', () {
      const granted = <String>[];
      expect(redirectFor(BranchRoutes.list, granted), AppRoutes.home);
      expect(redirectFor(BranchRoutes.add, granted), AppRoutes.home);
      expect(redirectFor(BranchRoutes.coverage, granted), AppRoutes.home);
      expect(
        redirectFor(BranchRoutes.detailsFor('b1'), granted),
        AppRoutes.home,
      );
    });
  });

  group('providerRoutePermissions — real Services rules (RBAC Phase 7E)', () {
    String? redirectFor(
      String location,
      Iterable<String> granted, {
      bool isProviderOwner = false,
    }) {
      return resolveProviderRedirect(
        location: location,
        isAuthenticated: true,
        canManageOrganization: false,
        isProviderOwner: isProviderOwner,
        permissions: PermissionSet.from(granted),
        permissionsResolved: true,
        table: providerRoutePermissions,
      );
    }

    test(
      'the reported worker (view-only) reaches the list and a service '
      'detail — the exact bug this phase closes',
      () {
        final granted = [ServicePermissions.providerServiceView];
        expect(redirectFor(ServiceRoutes.list, granted), isNull);
        expect(redirectFor(ServiceRoutes.detailsFor('svc-1'), granted), isNull);
      },
    );

    test('without the permission, the list and a detail are denied home', () {
      expect(redirectFor(ServiceRoutes.list, []), AppRoutes.home);
      expect(
        redirectFor(ServiceRoutes.detailsFor('svc-1'), []),
        AppRoutes.home,
      );
    });

    test(
      'a worker is redirected home from every owner-only sub-surface, even '
      'holding provider-service:view — no permission grants these (finding '
      'G3), so the owner-only guard fires before the permission table is '
      'ever consulted',
      () {
        final granted = [ServicePermissions.providerServiceView];
        expect(redirectFor(ServiceRoutes.add, granted), AppRoutes.home);
        expect(redirectFor(ServiceRoutes.requestNew, granted), AppRoutes.home);
        expect(
          redirectFor(ServiceRoutes.requestDetailsFor('r1'), granted),
          AppRoutes.home,
        );
        expect(
          redirectFor(ServiceRoutes.editFor('svc-1'), granted),
          AppRoutes.home,
        );
      },
    );

    test('an owner (provider:*) reaches every Services route', () {
      const granted = ['provider:*'];
      for (final location in [
        ServiceRoutes.list,
        ServiceRoutes.add,
        ServiceRoutes.requestNew,
        ServiceRoutes.requestDetailsFor('r1'),
        ServiceRoutes.detailsFor('svc-1'),
        ServiceRoutes.editFor('svc-1'),
      ]) {
        expect(
          redirectFor(location, granted, isProviderOwner: true),
          isNull,
          reason: '$location must be reachable by the owner',
        );
      }
    });
  });

  group('providerRoutePermissions — real Workers rules (RBAC Phase 7E)', () {
    String? redirectFor(
      String location,
      Iterable<String> granted, {
      bool isProviderOwner = false,
    }) {
      return resolveProviderRedirect(
        location: location,
        isAuthenticated: true,
        canManageOrganization: false,
        isOrganizationTeamMember: true,
        isProviderOwner: isProviderOwner,
        permissions: PermissionSet.from(granted),
        permissionsResolved: true,
        table: providerRoutePermissions,
      );
    }

    test('worker:view reaches the list and a worker detail', () {
      final granted = [WorkerPermissions.view];
      expect(redirectFor(WorkerRoutes.list, granted), isNull);
      expect(redirectFor(WorkerRoutes.detailsFor('w1'), granted), isNull);
    });

    test('without worker:view, the list and a detail are denied home', () {
      expect(redirectFor(WorkerRoutes.list, []), AppRoutes.home);
      expect(redirectFor(WorkerRoutes.detailsFor('w1'), []), AppRoutes.home);
    });

    test(
      'a manager holding worker:view is still redirected home from invite '
      'and edit — owner-only, no permission grants either write',
      () {
        final granted = [WorkerPermissions.view];
        expect(redirectFor(WorkerRoutes.add, granted), AppRoutes.home);
        expect(
          redirectFor(WorkerRoutes.editWorkerFor('w1'), granted),
          AppRoutes.home,
        );
      },
    );

    test('an owner (provider:*) reaches every Workers route', () {
      const granted = ['provider:*'];
      for (final location in [
        WorkerRoutes.list,
        WorkerRoutes.add,
        WorkerRoutes.detailsFor('w1'),
        WorkerRoutes.editWorkerFor('w1'),
      ]) {
        expect(
          redirectFor(location, granted, isProviderOwner: true),
          isNull,
          reason: '$location must be reachable by the owner',
        );
      }
    });
  });

  group('providerRoutePermissions — no-redirect-loop invariant', () {
    test('every denial target is itself free of a permission requirement', () {
      for (final rule in providerRoutePermissions.rules) {
        final target = rule.denyRedirect ?? AppRoutes.home;
        final targetRule = providerRoutePermissions.ruleFor(target);
        expect(
          targetRule,
          isNull,
          reason:
              'Rule denying "$target" would itself be denied, creating a '
              'redirect loop.',
        );
      }
    });
  });

  group('refreshListenable re-evaluation (real GoRouter)', () {
    testWidgets(
      're-runs redirect when the merged authorization listenable notifies, '
      'without a markNeedsBuild-during-build crash',
      (tester) async {
        final authStatus = ChangeNotifier();
        final authorizationChanges = ChangeNotifier();
        var redirectCalls = 0;

        final router = GoRouter(
          initialLocation: '/a',
          refreshListenable: Listenable.merge([
            authStatus,
            authorizationChanges,
          ]),
          redirect: (context, state) {
            redirectCalls++;
            return null;
          },
          routes: [GoRoute(path: '/a', builder: (_, _) => const SizedBox())],
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        final callsAfterInitial = redirectCalls;

        // Simulate exactly what AuthorizationSignal does: notify after a
        // permission change lands, outside the widget build phase.
        authorizationChanges.notifyListeners();
        await tester.pumpAndSettle();

        expect(
          redirectCalls,
          greaterThan(callsAfterInitial),
          reason: 'the merged listenable must trigger a fresh redirect pass',
        );
        // Reaching here at all (no thrown FlutterError) proves the merge
        // does not trip a "setState()/markNeedsBuild() called during build"
        // exception — the concrete risk flagged for this change.
      },
    );
  });
}
