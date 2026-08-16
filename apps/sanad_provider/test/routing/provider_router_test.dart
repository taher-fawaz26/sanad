import 'package:auth/auth.dart';
import 'package:branches/branches.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_rbac/provider_rbac.dart';
import 'package:sanad_provider/src/features/organization_settings/organization_settings.dart';
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
    }

    test('individual provider is NOT redirected away from the Settings tab '
        '(its builder renders General Settings for them)', () {
      expect(
        resolveProviderRedirect(
          location: OrganizationSettingsRoutes.hub,
          isAuthenticated: true,
          canManageOrganization: false,
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
        ),
        isNull,
      );
    });

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
}
