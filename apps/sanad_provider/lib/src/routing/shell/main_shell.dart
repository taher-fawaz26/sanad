import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainShell extends StatefulWidget {
  const MainShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late final NotchBottomBarController _bottomNavController =
      NotchBottomBarController(
        index: 2, // Center index for 5 items
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: AppBottomNavBar(
        controller: _bottomNavController,
        currentIndex: widget.navigationShell.currentIndex,
        onTap: (index) => widget.navigationShell.goBranch(
          index,
          initialLocation: index == widget.navigationShell.currentIndex,
        ),
        centerAction: AppBottomNavCenterAction(
          iconAsset: AppNavigationIcons.centerAction,
          semanticLabel: 'nav.create'.tr(),
          onTap: () {
            // TODO: Implement center action
          },
        ),
        items: [
          AppBottomNavItem(
            iconAsset: AppNavigationIcons.home,
            label: 'nav.home'.tr(),
          ),
          AppBottomNavItem(
            iconAsset: AppNavigationIcons.service,
            label: 'nav.requests'.tr(),
          ),
          AppBottomNavItem(
            iconAsset: AppNavigationIcons.messages,
            label: 'nav.messages'.tr(),
          ),
          AppBottomNavItem(
            iconAsset: AppNavigationIcons.settings,
            label: 'nav.settings'.tr(),
          ),
          AppBottomNavItem(
            iconAsset: AppNavigationIcons.home, // Placeholder icon
            label: 'nav.more'.tr(),
          ),
        ],
      ),
    );
  }
}
