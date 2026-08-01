import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_provider/src/routing/app_routes.dart';
import 'package:sanad_provider/src/routing/shell/provider_bottom_nav.dart';
import 'package:sanad_provider/src/routing/shell/settings_expandable_menu.dart';

class MainShell extends StatefulWidget {
  const MainShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _settingsMenuController = SettingsExpandableMenuController();
  late final Widget _settingsMenu;

  @override
  void initState() {
    super.initState();
    _settingsMenu = SettingsExpandableMenu(
      controller: _settingsMenuController,
      onGeneralSettings: () => _navigateToSettingsTab(0),
      onAccountSettings: () => _navigateToSettingsTab(1),
    );
  }

  @override
  void dispose() {
    _settingsMenuController.dispose();
    super.dispose();
  }

  void _goBranch(ProviderBottomNavDestination destination) {
    widget.navigationShell.goBranch(
      destination.shellBranchIndex,
      initialLocation:
          destination.shellBranchIndex == widget.navigationShell.currentIndex,
    );
  }

  void _toggleSettingsMenu() => _settingsMenuController.toggle();

  void _closeSettingsMenu() => _settingsMenuController.close();

  void _navigateToSettingsTab(int tab) {
    _closeSettingsMenu();
    context.go('${AppRoutes.settings}?tab=$tab');
  }

  void _onBarTap(int barIndex) {
    final destination = ProviderBottomNavDestination.fromBarIndex(barIndex);
    if (destination == null) return;

    if (destination.opensExpandableMenu) {
      _toggleSettingsMenu();
      return;
    }

    if (destination.navigatesOnTap) {
      _goBranch(destination);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeDestination = ProviderBottomNavDestination.fromShellBranch(
      widget.navigationShell.currentIndex,
    );
    final currentBarIndex = activeDestination?.barIndex ?? 0;

    return ValueListenableBuilder<bool>(
      valueListenable: _settingsMenuController.isExpanded,
      child: _settingsMenu,
      builder: (context, isSettingsExpanded, settingsMenu) {
        return Scaffold(
          floatingActionButtonLocation: _settingsMenuController.fabLocation,
          floatingActionButton: settingsMenu,
          body: Stack(
            fit: StackFit.expand,
            children: [
              widget.navigationShell,
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: !isSettingsExpanded,
                  child: AnimatedOpacity(
                    opacity: isSettingsExpanded ? 1 : 0,
                    duration: SettingsExpandableMenu.animationDuration,
                    curve: Curves.easeOutCubic,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _closeSettingsMenu,
                      child: ColoredBox(
                        color: Colors.black.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: AppBottomNavBar(
            currentIndex: currentBarIndex,
            dimNonSettingsItems: isSettingsExpanded,
            blockNonSettingsInteractions: isSettingsExpanded,
            onTap: _onBarTap,
            centerAction: AppBottomNavCenterAction(
              iconAsset: AppNavigationIcons.centerAction,
              semanticLabel: 'nav.requests'.tr(),
              selected:
                  activeDestination == ProviderBottomNavDestination.requests,
              onTap: isSettingsExpanded
                  ? null
                  : () => _goBranch(ProviderBottomNavDestination.requests),
            ),
            items: ProviderBottomNavDestination.items(),
          ),
        );
      },
    );
  }
}
