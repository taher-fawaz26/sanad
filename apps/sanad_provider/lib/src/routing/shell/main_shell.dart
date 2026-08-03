import 'package:bottom_nav_bar/bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_provider/src/routing/shell/provider_bottom_nav.dart';
import 'package:sanad_provider/src/routing/shell/provider_bottom_nav_items.dart';
import 'package:sanad_provider/src/routing/shell/provider_bottom_nav_theme.dart';

class MainShell extends StatefulWidget {
  const MainShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late final BottomNavController _bottomNavController;

  @override
  void initState() {
    super.initState();
    _bottomNavController = BottomNavController();
  }

  @override
  void dispose() {
    _bottomNavController.dispose();
    super.dispose();
  }

  void _goBranch(ProviderBottomNavDestination destination) {
    widget.navigationShell.goBranch(
      destination.shellBranchIndex,
      initialLocation:
          destination.shellBranchIndex == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeDestination = ProviderBottomNavDestination.fromShellBranch(
          widget.navigationShell.currentIndex,
        ) ??
        ProviderBottomNavDestination.home;

    final theme = providerBottomNavTheme(context);
    final destinations = ProviderBottomNavItems.destinations(context);
    final actions = ProviderBottomNavItems.actions(context);

    return Scaffold(
      extendBody: true,
      body: widget.navigationShell,
      floatingActionButtonLocation: BottomNavExpandableCenter.fabLocation,
      floatingActionButton: BottomNavExpandableCenter(
        actions: actions,
        selectedItem: activeDestination,
        controller: _bottomNavController,
        theme: theme,
        onActionSelected: _goBranch,
      ),
      bottomNavigationBar: BottomNavBar(
        destinations: destinations,
        selectedItem: activeDestination,
        theme: theme,
        onDestinationSelected: _goBranch,
      ),
    );
  }
}
