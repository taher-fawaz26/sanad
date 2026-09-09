import 'package:authorization/authorization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_provider/src/features/requests/requests.dart';
import 'package:sanad_provider/src/routing/shell/provider_bottom_nav.dart';
import 'package:sanad_provider/src/routing/shell/provider_bottom_nav_permissions.dart';
import 'package:services/services.dart';

import '../support/fake_authorization_reader.dart';

void main() {
  group('visibleBottomNavTabs (RBAC Phase 7D)', () {
    test(
      'a worker with neither service nor client-request view sees only the '
      'ungated tabs',
      () {
        final reader = FakeAuthorizationReader(
          permissions: PermissionSet.from(const [
            'provider:branch:view',
            'provider:catalog-service:view',
          ]),
        );

        // Home, Messages and Settings carry no gate: the first two are still
        // placeholder pages with no backend fetch, and Settings opens a menu
        // sheet rather than navigating.
        expect(visibleBottomNavTabs(reader), [
          ProviderBottomNavDestination.home,
          ProviderBottomNavDestination.messages,
          ProviderBottomNavDestination.settings,
        ]);
      },
    );

    test(
      'client-request:view alone reveals Requests but not Services',
      () {
        // The workspace is entirely `GET /provider/requests`; without the view
        // permission every screen behind that tab answers 403.
        final reader = FakeAuthorizationReader(
          permissions: PermissionSet.from(const [
            ClientRequestPermissions.view,
          ]),
        );

        expect(
          visibleBottomNavTabs(reader),
          contains(ProviderBottomNavDestination.requests),
        );
        expect(
          visibleBottomNavTabs(reader),
          isNot(contains(ProviderBottomNavDestination.services)),
        );
      },
    );

    test(
      'a worker with both view permissions sees every permanent tab, in '
      'permanentTabs order',
      () {
        final reader = FakeAuthorizationReader(
          permissions: PermissionSet.from(const [
            ServicePermissions.providerServiceView,
            ClientRequestPermissions.view,
          ]),
        );

        expect(
          visibleBottomNavTabs(reader),
          ProviderBottomNavDestination.permanentTabs,
        );
      },
    );

    test('an owner (provider:*) sees every permanent tab', () {
      final reader = FakeAuthorizationReader(
        permissions: PermissionSet.from(const ['provider:*']),
      );

      expect(
        visibleBottomNavTabs(reader),
        ProviderBottomNavDestination.permanentTabs,
      );
    });

    test(
      'unresolved permissions hide both gated tabs — fail closed, not open',
      () {
        final reader = FakeAuthorizationReader(
          permissions: PermissionSet.from(const [
            ServicePermissions.providerServiceView,
            ClientRequestPermissions.view,
          ]),
          isResolved: false,
        );

        expect(
          visibleBottomNavTabs(reader),
          isNot(contains(ProviderBottomNavDestination.services)),
        );
        expect(
          visibleBottomNavTabs(reader),
          isNot(contains(ProviderBottomNavDestination.requests)),
        );
      },
    );

    test('an empty, resolved permission set hides both gated tabs', () {
      final reader = FakeAuthorizationReader();

      expect(visibleBottomNavTabs(reader), [
        ProviderBottomNavDestination.home,
        ProviderBottomNavDestination.messages,
        ProviderBottomNavDestination.settings,
      ]);
    });

    test(
      'every visible tab still round-trips through shellBranchIndex — '
      'filtering never touches the static branch mapping',
      () {
        final reader = FakeAuthorizationReader(
          permissions: PermissionSet.from(const [
            ServicePermissions.providerServiceView,
            ClientRequestPermissions.view,
          ]),
        );

        for (final tab in visibleBottomNavTabs(reader)) {
          expect(
            ProviderBottomNavDestination.fromShellBranch(tab.shellBranchIndex),
            tab,
          );
        }
      },
    );
  });
}
