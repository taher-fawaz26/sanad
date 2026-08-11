import 'package:auth/auth.dart';
import 'package:branches/branches.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_rbac/provider_rbac.dart';
import 'package:sanad_provider/src/features/organization_settings/organization_settings.dart';
import 'package:sanad_provider/src/routing/provider_router.dart';
import 'package:services/services.dart';
import 'package:workers/workers.dart';

void main() {
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
      OrganizationSettingsRoutes.hub,
    ];

    for (final location in orgOnlyRoutes) {
      test('individual provider hitting $location is redirected to General '
          'Settings', () {
        expect(
          resolveProviderRedirect(
            location: location,
            isAuthenticated: true,
            canManageOrganization: false,
          ),
          OrganizationSettingsRoutes.general,
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

    test('a branch detail/edit deep link is org-only', () {
      expect(
        resolveProviderRedirect(
          location: BranchRoutes.detailsFor('b1'),
          isAuthenticated: true,
          canManageOrganization: false,
        ),
        OrganizationSettingsRoutes.general,
      );
      expect(
        resolveProviderRedirect(
          location: BranchRoutes.editFor('b1'),
          isAuthenticated: true,
          canManageOrganization: false,
        ),
        OrganizationSettingsRoutes.general,
      );
    });

    test('a worker/invitation deep link under /workers/ is org-only', () {
      expect(
        resolveProviderRedirect(
          location: '/workers/w1',
          isAuthenticated: true,
          canManageOrganization: false,
        ),
        OrganizationSettingsRoutes.general,
      );
    });

    test('a roles-permissions deep link is org-only', () {
      expect(
        resolveProviderRedirect(
          location: ProviderRbacRoutes.editFor('r1'),
          isAuthenticated: true,
          canManageOrganization: false,
        ),
        OrganizationSettingsRoutes.general,
      );
    });
  });
}
