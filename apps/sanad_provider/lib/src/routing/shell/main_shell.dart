import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainShell extends StatelessWidget {
  const MainShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        items: [
          AppBottomNavItem(
            iconAsset: AppSvgs.navHome,
            label: 'nav.home'.tr(),
          ),
          AppBottomNavItem(
            iconAsset: AppSvgs.navRequest,
            label: 'nav.requests'.tr(),
          ),
          AppBottomNavItem(
            iconAsset: AppSvgs.navMessage,
            label: 'nav.messages'.tr(),
          ),
          AppBottomNavItem(
            iconAsset: AppSvgs.navSettings,
            label: 'nav.settings'.tr(),
          ),
        ],
      ),
    );
  }
}
