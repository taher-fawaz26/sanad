import 'package:bottom_nav_bar/bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_provider/src/features/organization_settings/organization_settings.dart';
import 'package:sanad_provider/src/routing/shell/provider_bottom_nav.dart';
import 'package:sanad_provider/src/routing/shell/provider_bottom_nav_items.dart';
import 'package:sanad_provider/src/routing/shell/provider_bottom_nav_theme.dart';
import 'package:shared_ui/shared_ui.dart';

/// Provider app shell — flat bottom tab bar (Figma `1526:12109`).
class MainShell extends StatefulWidget {
  /// Creates the provider main shell.
  const MainShell({required this.navigationShell, super.key});

  /// Indexed-stack navigation shell from GoRouter.
  final StatefulNavigationShell navigationShell;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  // Shared across every tab: only one branch is ever visible at a time, so a
  // single controller can drive the bottom bar's hide-on-scroll regardless
  // of which tab's scroll view is currently attached to it.
  final _scrollController = ScrollController();

  // Decides show/hide from the shared scroll controller — never hides
  // short/non-scrollable content, ignores pull-to-refresh overscroll, and
  // always shows at the top (see NavVisibilityController for the full rules).
  final _navVisibility = NavVisibilityController();

  // Anchors the settings popover to the actual rendered Settings tab tile.
  final GlobalKey _settingsTileKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _navVisibility.attach(_scrollController);
  }

  @override
  void dispose() {
    _navVisibility.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _goBranch(
    BuildContext context,
    ProviderBottomNavDestination destination,
  ) {
    if (destination.opensSettingsMenu) {
      showSettingsMenuSheet(context, anchorKey: _settingsTileKey);
      return;
    }

    widget.navigationShell.goBranch(
      destination.shellBranchIndex,
      initialLocation:
          destination.shellBranchIndex == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeDestination =
        ProviderBottomNavDestination.fromShellBranch(
          widget.navigationShell.currentIndex,
        ) ??
        ProviderBottomNavDestination.home;

    // Falls back to Home if a non-permanent-tab branch is ever active, so no
    // invisible tab appears highlighted.
    final selectedItem = activeDestination.isPermanentTab
        ? activeDestination
        : ProviderBottomNavDestination.home;

    final navTheme = providerBottomNavTheme(context);
    // NavVisibility sizes its child with a fixed SizedBox (defaulting to the
    // 56dp AppBar height) rather than measuring it — passing our actual
    // total height (bar + bottom inset + safe area) keeps it from clamping
    // BottomNavBar down and overflowing its destination tiles.
    final barTotalHeight =
        navTheme.barHeight +
        navTheme.bottomInset +
        MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      body: MainNavScrollController(
        controller: _scrollController,
        child: widget.navigationShell,
      ),
      bottomNavigationBar: NavVisibility(
        controller: _navVisibility,
        preferredHeight: barTotalHeight,
        child: BottomNavBar(
          destinations: ProviderBottomNavItems.destinations(context),
          selectedItem: selectedItem,
          theme: navTheme,
          destinationKeys: {
            ProviderBottomNavDestination.settings: _settingsTileKey,
          },
          onDestinationSelected: (destination) =>
              _goBranch(context, destination),
        ),
      ),
    );
  }
}
