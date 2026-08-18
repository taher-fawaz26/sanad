import 'package:authorization/authorization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_provider/src/routing/shell/provider_bottom_nav.dart';
import 'package:sanad_provider/src/routing/shell/provider_bottom_nav_permissions.dart';
import 'package:services/services.dart';

import '../support/fake_authorization_reader.dart';

void main() {
  group('visibleBottomNavTabs (RBAC Phase 7D)', () {
    test(
      'a worker without provider-service:view sees every tab except '
      'Services',
      () {
        final reader = FakeAuthorizationReader(
          permissions: PermissionSet.from(const [
            'provider:branch:view',
            'provider:catalog-service:view',
          ]),
        );

        expect(visibleBottomNavTabs(reader), [
          ProviderBottomNavDestination.home,
          ProviderBottomNavDestination.requests,
          ProviderBottomNavDestination.messages,
          ProviderBottomNavDestination.settings,
        ]);
      },
    );

    test(
      'a worker WITH provider-service:view sees every permanent tab, in '
      'permanentTabs order',
      () {
        final reader = FakeAuthorizationReader(
          permissions: PermissionSet.from(const [
            ServicePermissions.providerServiceView,
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

    test('unresolved permissions hide Services — fail closed, not open', () {
      final reader = FakeAuthorizationReader(
        permissions: PermissionSet.from(const [
          ServicePermissions.providerServiceView,
        ]),
        isResolved: false,
      );

      expect(
        visibleBottomNavTabs(reader),
        isNot(contains(ProviderBottomNavDestination.services)),
      );
    });

    test('an empty, resolved permission set hides only Services', () {
      final reader = FakeAuthorizationReader();

      expect(visibleBottomNavTabs(reader), [
        ProviderBottomNavDestination.home,
        ProviderBottomNavDestination.requests,
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
