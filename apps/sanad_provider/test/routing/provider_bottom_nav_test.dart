import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_provider/src/routing/app_routes.dart';
import 'package:sanad_provider/src/routing/shell/provider_bottom_nav.dart';

void main() {
  group('ProviderBottomNavDestination', () {
    test('bar indices match visual order', () {
      expect(ProviderBottomNavDestination.home.barIndex, 0);
      expect(ProviderBottomNavDestination.messages.barIndex, 1);
      expect(ProviderBottomNavDestination.requests.barIndex, 2);
      expect(ProviderBottomNavDestination.services.barIndex, 3);
      expect(ProviderBottomNavDestination.settings.barIndex, 4);
    });

    test('shell branch indices align with bar indices', () {
      for (final destination in ProviderBottomNavDestination.values) {
        expect(
          destination.shellBranchIndex,
          destination.barIndex,
          reason: '${destination.name} branch/bar mismatch',
        );
      }
    });

    test('fromBarIndex and fromShellBranch round-trip', () {
      for (final destination in ProviderBottomNavDestination.values) {
        expect(
          ProviderBottomNavDestination.fromBarIndex(destination.barIndex),
          destination,
        );
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

    test('requests uses center FAB slot', () {
      expect(ProviderBottomNavDestination.requests.isCenterFab, isTrue);
      expect(ProviderBottomNavDestination.centerFabBarIndex, 2);
      expect(ProviderBottomNavDestination.home.isCenterFab, isFalse);
    });

    test('settings opens expandable menu instead of navigating on tap', () {
      expect(ProviderBottomNavDestination.settings.opensExpandableMenu, isTrue);
      expect(ProviderBottomNavDestination.settings.navigatesOnTap, isFalse);
      expect(ProviderBottomNavDestination.settingsBarIndex, 4);
    });

    test('non-navigating destinations are settings only', () {
      final nonNavigating = ProviderBottomNavDestination.values
          .where((destination) => !destination.navigatesOnTap)
          .toList();
      expect(nonNavigating, [ProviderBottomNavDestination.settings]);
    });
  });
}
