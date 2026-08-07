import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/theme/tokens/tab_bar_tokens.dart';
import 'package:flutter/material.dart';

/// Figma `Bars / Tabs` (`40:6974`).
class AppTabBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTabBar({
    required this.tabs,
    required this.controller,
    super.key,
    this.onTap,
  });

  final List<String> tabs;
  final TabController controller;
  final ValueChanged<int>? onTap;

  @override
  Size get preferredSize => Size.fromHeight(AppDimension.buttonMd);

  @override
  Widget build(BuildContext context) {
    final spec = context.appTabBarTheme.spec;

    return Material(
      color: spec.backgroundColor,
      child: SizedBox(
        height: spec.height,
        child: TabBar(
          controller: controller,
          onTap: onTap,
          tabs: tabs.map((label) => Tab(text: label)).toList(),
          labelColor: spec.selectedLabelColor,
          unselectedLabelColor: spec.unselectedLabelColor,
          labelStyle: spec.labelStyle,
          unselectedLabelStyle: spec.unselectedLabelStyle,
          indicatorColor: spec.indicatorColor,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(
              color: spec.indicatorColor,
              width: spec.indicatorWeight,
            ),
            borderRadius: spec.indicatorBorderRadius,
          ),
          dividerColor: spec.dividerColor,
          dividerHeight: 0,
          overlayColor: spec.overlayColor,
          splashFactory: NoSplash.splashFactory,
        ),
      ),
    );
  }
}
