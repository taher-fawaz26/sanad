import 'package:app_assets/app_assets.dart';
import 'package:design_system/src/theme/tokens/bottom_nav_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Figma `Bars / Tab Bars: Icon & Text` (`97:4367`).
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  final List<AppBottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final spec = context.appBottomNavTheme.spec;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final useTwoTabDarkBg =
        isDark && items.length == 2 && spec.twoTabDarkBackground != null;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: useTwoTabDarkBg
            ? spec.twoTabDarkBackground
            : spec.backgroundColor,
        boxShadow: spec.shadow,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: spec.height,
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final selected = index == currentIndex;
              return Expanded(
                child: _BottomNavTab(
                  item: item,
                  selected: selected,
                  spec: spec,
                  onTap: () => onTap(index),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _BottomNavTab extends StatelessWidget {
  const _BottomNavTab({
    required this.item,
    required this.selected,
    required this.spec,
    required this.onTap,
  });

  final AppBottomNavItem item;
  final bool selected;
  final BottomNavStyleSpec spec;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final itemSpec = spec.itemStyle;
    final iconColor = selected
        ? itemSpec.selectedIconColor
        : itemSpec.unselectedIconColor;
    final labelStyle = selected
        ? itemSpec.selectedLabelStyle
        : itemSpec.unselectedLabelStyle;

    return Semantics(
      label: item.label,
      selected: selected,
      button: true,
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: itemSpec.itemBackgroundColor,
        child: InkWell(
          onTap: onTap,
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                item.iconAsset,
                package: AppAssets.package,
                width: spec.iconSize,
                height: spec.iconSize,
                colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
              ),
              SizedBox(height: spec.iconLabelGap),
              Text(item.label, style: labelStyle),
            ],
          ),
        ),
      ),
    );
  }
}
