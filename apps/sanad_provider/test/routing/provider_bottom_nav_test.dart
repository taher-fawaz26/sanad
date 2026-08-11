import 'package:app_assets/app_assets.dart';
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

    test('permanent tabs order: Home, Services, Requests, Messages, '
        'Settings', () {
      expect(ProviderBottomNavDestination.permanentTabs, [
        ProviderBottomNavDestination.home,
        ProviderBottomNavDestination.services,
        ProviderBottomNavDestination.requests,
        ProviderBottomNavDestination.messages,
        ProviderBottomNavDestination.settings,
      ]);
      expect(ProviderBottomNavDestination.home.isPermanentTab, isTrue);
      expect(ProviderBottomNavDestination.services.isPermanentTab, isTrue);
      expect(ProviderBottomNavDestination.requests.isPermanentTab, isTrue);
      expect(ProviderBottomNavDestination.messages.isPermanentTab, isTrue);
      expect(ProviderBottomNavDestination.settings.isPermanentTab, isTrue);
    });

    test('Services sits immediately after Home and before Requests', () {
      final tabs = ProviderBottomNavDestination.permanentTabs;
      final homeIndex = tabs.indexOf(ProviderBottomNavDestination.home);
      final servicesIndex = tabs.indexOf(ProviderBottomNavDestination.services);
      final requestsIndex = tabs.indexOf(ProviderBottomNavDestination.requests);
      expect(servicesIndex, homeIndex + 1);
      expect(requestsIndex, servicesIndex + 1);
    });

    test('Services reuses the existing service.svg navigation icon asset', () {
      expect(
        ProviderBottomNavDestination.services.iconAsset,
        AppNavigationIcons.service,
      );
      expect(
        ProviderBottomNavDestination.services.selectedIconAsset,
        AppNavigationIcons.serviceFilled,
      );
    });

    test('settings opens menu sheet instead of navigating immediately', () {
      expect(
        ProviderBottomNavDestination.settings.opensSettingsMenu,
        isTrue,
      );
      expect(ProviderBottomNavDestination.home.opensSettingsMenu, isFalse);
    });
  });
}
