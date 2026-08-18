import 'package:auth/auth.dart';
import 'package:authorization/authorization.dart';
import 'package:bottom_nav_bar/bottom_nav_bar.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_provider/src/features/organization_settings/organization_settings.dart';
import 'package:sanad_provider/src/routing/provider_capabilities.dart';
import 'package:sanad_provider/src/routing/shell/provider_bottom_nav.dart';
import 'package:sanad_provider/src/routing/shell/provider_bottom_nav_items.dart';
import 'package:sanad_provider/src/routing/shell/provider_bottom_nav_permissions.dart';
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

  late final AuthorizationReader _authorizationReader;

  @override
  void initState() {
    super.initState();
    _navVisibility.attach(_scrollController);
    _authorizationReader = sl<AuthorizationReader>()
      ..addListener(_onAuthorizationChanged);
  }

  @override
  void dispose() {
    _authorizationReader.removeListener(_onAuthorizationChanged);
    _navVisibility.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Tabs are hidden, not just disabled, when their permission is revoked
  // (RBAC D1) — a role change mid-session must rebuild the bar with the tile
  // gone, not merely non-interactive.
  void _onAuthorizationChanged() => setState(() {});

  void _goBranch(
    BuildContext context,
    ProviderBottomNavDestination destination,
  ) {
    if (destination.opensSettingsMenu) {
      showSettingsMenuSheet(
        context,
        isProviderOwner: sl<SessionManager>().isProviderOwner,
        anchorKey: _settingsTileKey,
      );
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
    final visibleTabs = visibleBottomNavTabs(_authorizationReader);

    final activeDestination =
        ProviderBottomNavDestination.fromShellBranch(
          widget.navigationShell.currentIndex,
        ) ??
        ProviderBottomNavDestination.home;

    // Falls back to Home if the active branch's tab isn't one of today's
    // visible tabs — either it was never a permanent tab, or its permission
    // was revoked mid-session (see [_onAuthorizationChanged]) — so no
    // invisible tab is ever left highlighted.
    final selectedItem = visibleTabs.contains(activeDestination)
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
          destinations: ProviderBottomNavItems.destinations(
            context,
            visibleTabs,
          ),
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
