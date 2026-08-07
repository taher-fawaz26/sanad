import 'package:bottom_nav_bar/bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:organization_settings/organization_settings.dart';
import 'package:sanad_provider/src/routing/shell/provider_bottom_nav.dart';
import 'package:sanad_provider/src/routing/shell/provider_bottom_nav_items.dart';
import 'package:sanad_provider/src/routing/shell/provider_bottom_nav_theme.dart';

/// Provider app shell — flat bottom tab bar (Figma `1526:12109`).
class MainShell extends StatelessWidget {
  /// Creates the provider main shell.
  const MainShell({required this.navigationShell, super.key});

  /// Indexed-stack navigation shell from GoRouter.
  final StatefulNavigationShell navigationShell;

  void _goBranch(
    BuildContext context,
    ProviderBottomNavDestination destination,
  ) {
    if (destination.opensSettingsMenu) {
      showSettingsMenuSheet(context);
      return;
    }

    navigationShell.goBranch(
      destination.shellBranchIndex,
      initialLocation:
          destination.shellBranchIndex == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeDestination =
        ProviderBottomNavDestination.fromShellBranch(
          navigationShell.currentIndex,
        ) ??
        ProviderBottomNavDestination.home;

    // Services is deep-link only — keep Home selected when that branch is
    // somehow active so no invisible tab appears highlighted.
    final selectedItem = activeDestination.isPermanentTab
        ? activeDestination
        : ProviderBottomNavDestination.home;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavBar(
        destinations: ProviderBottomNavItems.destinations(context),
        selectedItem: selectedItem,
        theme: providerBottomNavTheme(context),
        onDestinationSelected: (destination) => _goBranch(context, destination),
      ),
    );
  }
}
