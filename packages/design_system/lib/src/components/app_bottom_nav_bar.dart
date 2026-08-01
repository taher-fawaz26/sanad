import 'package:curved_navigation_bar_pro/curved_navigation_bar_pro.dart';
import 'package:design_system/src/components/app_svg_picture.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/tokens/bottom_nav_tokens.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';

/// Bottom navigation bar item configuration.
@immutable
class AppBottomNavItem {
  /// Creates a bottom navigation item.
  const AppBottomNavItem({
    required this.iconAsset,
    required this.label,
    this.semanticLabel,
    this.enabled = true,
  });

  /// SVG icon asset path from [AppNavigationIcons].
  final String iconAsset;

  /// Visible label below the icon.
  final String label;

  /// Accessibility label; defaults to [label].
  final String? semanticLabel;

  /// Whether this item can be tapped.
  final bool enabled;
}

/// Center floating action button configuration.
@immutable
class AppBottomNavCenterAction {
  /// Creates a center action configuration.
  const AppBottomNavCenterAction({
    required this.iconAsset,
    this.semanticLabel,
    this.onTap,
    this.selected = false,
    this.enabled = true,
  });

  /// SVG icon asset path for the center button.
  final String iconAsset;

  /// Accessibility label for the center button.
  final String? semanticLabel;

  /// Tap callback; when null, the button is non-interactive.
  final VoidCallback? onTap;

  /// Whether the center button is in selected state (changes color).
  final bool selected;

  /// Whether the center button can be tapped.
  final bool enabled;
}

/// Visual index reserved for the center FAB slot in [AppBottomNavBar].
const int kAppBottomNavCenterIndex = 2;

/// Visual index reserved for the Settings action in [AppBottomNavBar].
const int kAppBottomNavSettingsIndex = 4;

/// Notch bottom navigation bar with 5 items and a center floating action.
///
/// Built on the Sanad fork of `curved_navigation_bar_pro`, which mirrors FAB
/// and notch geometry under [Directionality.rtl].
/// Figma reference: `Nab-Bar` (`3148:27106`)
///
/// [currentIndex] and [onTap] use **visual / semantic** indices only:
/// `0` Home, `1` Messages, `2` Requests (center FAB), `3` Services, `4` Settings.
class AppBottomNavBar extends StatelessWidget {
  /// Creates a notch bottom navigation bar with 5 items.
  const AppBottomNavBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.centerAction,
    this.dimNonSettingsItems = false,
    this.blockNonSettingsInteractions = false,
    super.key,
  }) : assert(items.length == 5, 'AppBottomNavBar requires exactly 5 items');

  /// List of 5 navigation items in visual order (leading → trailing).
  final List<AppBottomNavItem> items;

  /// Currently selected visual item index (0-4).
  final int currentIndex;

  /// Called when a side item is tapped; receives the visual index (0-4).
  final ValueChanged<int> onTap;

  /// Configuration for the center floating action button at visual index `2`.
  final AppBottomNavCenterAction centerAction;

  /// When true, all items except [kAppBottomNavSettingsIndex] render at 40% opacity.
  final bool dimNonSettingsItems;

  /// When true, taps on non-settings items are ignored.
  final bool blockNonSettingsInteractions;

  void _handleTap(int index) {
    if (blockNonSettingsInteractions &&
        index != kAppBottomNavSettingsIndex) {
      return;
    }
    if (index == kAppBottomNavCenterIndex) {
      if (centerAction.enabled && centerAction.onTap != null) {
        centerAction.onTap!();
      }
      return;
    }

    final item = items[index];
    if (item.enabled) {
      onTap(index);
    }
  }

  Widget _svgIcon({
    required String asset,
    required Color color,
    required double size,
    required bool enabled,
    double opacity = 1,
  }) {
    return Opacity(
      opacity: enabled ? opacity : 0.5,
      child: AppSvgPicture.asset(
        asset,
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      ),
    );
  }

  /// Untinted SVG for the FAB bubble — tint comes from package [activeIconColor].
  Widget _fabActiveIcon({
    required String asset,
    required double size,
    required bool enabled,
    double opacity = 1,
  }) {
    return Opacity(
      opacity: enabled ? opacity : 0.5,
      child: AppSvgPicture.asset(
        asset,
        width: size,
        height: size,
      ),
    );
  }

  CurvedNavigationItemPro _buildItem({
    required AppBottomNavItem item,
    required int index,
    required AppColors colors,
    required AppTypography typography,
    required Brightness brightness,
  }) {
    final inactiveColor =
        BottomNavTokens.unselectedIconColor(colors, brightness);
    final iconSize = BottomNavTokens.kIconSize;
    final fabIconSize = BottomNavTokens.centerFabSize * 0.46;
    final dimOthers =
        dimNonSettingsItems && index != kAppBottomNavSettingsIndex;
    final itemOpacity = dimOthers ? 0.4 : 1.0;
    final isCenterSlot = index == kAppBottomNavCenterIndex;

    if (isCenterSlot) {
      final centerEnabled = centerAction.enabled && centerAction.onTap != null;

      return CurvedNavigationItemPro(
        label: item.label,
        inactiveWidget: _svgIcon(
          asset: centerAction.iconAsset,
          color: centerEnabled
              ? inactiveColor
              : BottomNavTokens.disabledIconColor(colors),
          size: iconSize,
          enabled: centerEnabled,
          opacity: itemOpacity,
        ),
        activeWidget: _fabActiveIcon(
          asset: centerAction.iconAsset,
          size: fabIconSize,
          enabled: centerEnabled,
          opacity: itemOpacity,
        ),
      );
    }

    final enabled = item.enabled;

    return CurvedNavigationItemPro(
      label: item.label,
      inactiveWidget: _svgIcon(
        asset: item.iconAsset,
        color: enabled
            ? inactiveColor
            : BottomNavTokens.disabledIconColor(colors),
        size: iconSize,
        enabled: enabled,
        opacity: itemOpacity,
      ),
      activeWidget: _fabActiveIcon(
        asset: item.iconAsset,
        size: fabIconSize,
        enabled: enabled,
        opacity: itemOpacity,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final brightness = Theme.of(context).brightness;
    final fabRadius = BottomNavTokens.centerFabSize / 2;

    final fabColor = currentIndex == kAppBottomNavCenterIndex
        ? (centerAction.selected
            ? BottomNavTokens.centerFabActiveColor(colors, brightness)
            : BottomNavTokens.centerFabInactiveColor(colors))
        : BottomNavTokens.centerFabActiveColor(colors, brightness);

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1,
      child: SafeArea(
        top: false,
        child: CurvedNavigationBarPro(
          currentIndex: currentIndex.clamp(0, items.length - 1),
          onTap: _handleTap,
          backgroundColor: BottomNavTokens.backgroundColor(colors, brightness),
          activeColor: BottomNavTokens.selectedIconColor(colors),
          inactiveColor: BottomNavTokens.unselectedIconColor(colors, brightness),
          fabColor: fabColor,
          activeIconColor: BottomNavTokens.centerFabIconColor(colors),
          barHeight: BottomNavTokens.bottomBarHeight,
          fabRadius: fabRadius,
          fabGap: BottomNavTokens.circleMargin,
          fabSink: BottomNavTokens.fabSink,
          notchShoulderRadius: BottomNavTokens.notchShoulderRadius,
          cornerRadius: BottomNavTokens.kBottomRadius,
          contentPadding: BottomNavTokens.contentPadding,
          elevation: BottomNavTokens.elevation,
          shadowColor: BottomNavTokens.shadowColor,
          animationDuration: Duration(
            milliseconds: BottomNavTokens.durationInMilliSeconds,
          ),
          animationCurve: BottomNavTokens.animationCurve,
          activeTextStyle: BottomNavTokens.selectedLabelStyle(
            typography,
            colors,
          ),
          inactiveTextStyle: BottomNavTokens.unselectedLabelStyle(
            typography,
            colors,
            brightness,
          ),
          showLabel: BottomNavTokens.showLabel,
          inactiveIconSize: BottomNavTokens.kIconSize,
          activeIconSize: fabRadius * 0.92,
          items: [
            for (var i = 0; i < items.length; i++)
              _buildItem(
                item: items[i],
                index: i,
                colors: colors,
                typography: typography,
                brightness: brightness,
              ),
          ],
        ),
      ),
    );
  }
}
