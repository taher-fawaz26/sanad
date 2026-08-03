import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_provider/src/routing/app_routes.dart';
import 'package:sanad_provider/src/routing/shell/provider_bottom_nav.dart';

void main() {
  group('ProviderBottomNavDestination', () {
    test('shell branch indices match enum order', () {
      expect(ProviderBottomNavDestination.home.shellBranchIndex, 0);
      expect(ProviderBottomNavDestination.messages.shellBranchIndex, 1);
      expect(ProviderBottomNavDestination.requests.shellBranchIndex, 2);
      expect(ProviderBottomNavDestination.services.shellBranchIndex, 3);
      expect(ProviderBottomNavDestination.settings.shellBranchIndex, 4);
    });

    test('fromShellBranch round-trips all destinations', () {
      for (final destination in ProviderBottomNavDestination.values) {
        expect(
          ProviderBottomNavDestination.fromShellBranch(
            destination.shellBranchIndex,
          ),
          destination,
        );
      }
    });

    test('routes map to AppRoutes', () {
      expect(ProviderBottomNavDestination.home.route, AppRoutes.home);
      expect(ProviderBottomNavDestination.messages.route, AppRoutes.messages);
      expect(ProviderBottomNavDestination.requests.route, AppRoutes.requests);
      expect(ProviderBottomNavDestination.services.route, AppRoutes.services);
      expect(ProviderBottomNavDestination.settings.route, AppRoutes.settings);
    });

    test('permanent tabs are home and settings only', () {
      expect(ProviderBottomNavDestination.permanentTabs, [
        ProviderBottomNavDestination.home,
        ProviderBottomNavDestination.settings,
      ]);
      expect(ProviderBottomNavDestination.home.isPermanentTab, isTrue);
      expect(ProviderBottomNavDestination.settings.isPermanentTab, isTrue);
      expect(ProviderBottomNavDestination.messages.isPermanentTab, isFalse);
    });

    test('fab actions are services requests messages in order', () {
      expect(ProviderBottomNavDestination.fabActions, [
        ProviderBottomNavDestination.services,
        ProviderBottomNavDestination.requests,
        ProviderBottomNavDestination.messages,
      ]);
      for (final action in ProviderBottomNavDestination.fabActions) {
        expect(action.isFabAction, isTrue);
      }
    });
  });
}
