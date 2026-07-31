import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:design_system/src/components/app_svg_picture.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/tokens/bottom_nav_tokens.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';

// Re-export package types for consumer convenience
export 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart'
    show NotchBottomBarController;

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

/// Notch bottom navigation bar with 5 items and a center floating action.
///
/// Built on top of `animated_notch_bottom_bar` package.
/// Figma reference: `Nab-Bar` (`3148:27106`)
///
/// Usage:
/// ```dart
/// AppBottomNavBar(
///   controller: NotchBottomBarController(index: 2), // Center index
///   items: [item1, item2, item3, item4, item5],
///   currentIndex: 0,
///   onTap: (index) => print('Tapped $index'),
///   centerAction: AppBottomNavCenterAction(
///     iconAsset: AppNavigationIcons.centerAction,
///     onTap: () => print('Center tapped'),
///   ),
/// )
/// ```
class AppBottomNavBar extends StatefulWidget {
  /// Creates a notch bottom navigation bar with 5 items.
  const AppBottomNavBar({
    required this.controller,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.centerAction,
    super.key,
  }) : assert(items.length == 5, 'AppBottomNavBar requires exactly 5 items');

  /// Controller for the notch animation — must be initialized with index 2.
  final NotchBottomBarController controller;

  /// List of 5 navigation items (2 before center, 2 after center, plus center).
  final List<AppBottomNavItem> items;

  /// Currently selected item index (0-4).
  final int currentIndex;

  /// Called when an item is tapped (receives index 0-4).
  final ValueChanged<int> onTap;

  /// Configuration for the center floating action button.
  final AppBottomNavCenterAction centerAction;

  @override
  State<AppBottomNavBar> createState() => _AppBottomNavBarState();
}

class _AppBottomNavBarState extends State<AppBottomNavBar> {
  @override
  void initState() {
    super.initState();
    _ensureCenterNotch();
  }

  @override
  void didUpdateWidget(covariant AppBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ensureCenterNotch();
  }

  void _ensureCenterNotch() {
    // Keep notch locked at center (index 2 for 5 items)
    if (widget.controller.index != 2) {
      widget.controller.index = 2;
    }
  }

  void _handleTap(int barIndex) {
    if (barIndex == 2) {
      // Center FAB tapped
      if (widget.centerAction.enabled && widget.centerAction.onTap != null) {
        widget.centerAction.onTap!();
      }
      return;
    }

    // Regular item tapped
    final item = widget.items[barIndex];
    if (item.enabled) {
      widget.onTap(barIndex);
    }
  }

  List<BottomBarItem> _buildBarItems() {
    final colors = context.appColors;
    final typography = context.appTypography;
    final brightness = Theme.of(context).brightness;

    return List.generate(5, (index) {
      if (index == 2) {
        // Center slot — invisible placeholder
        return const BottomBarItem(
          inActiveItem: SizedBox(
            width: BottomNavTokens.kIconSize,
            height: BottomNavTokens.kIconSize,
          ),
          activeItem: SizedBox(
            width: BottomNavTokens.kIconSize,
            height: BottomNavTokens.kIconSize,
          ),
        );
      }

      final item = widget.items[index];
      final isSelected = index == widget.currentIndex;

      return BottomBarItem(
        inActiveItem: _AnimatedNavIcon(
          asset: item.iconAsset,
          label: item.label,
          semanticLabel: item.semanticLabel,
          selected: isSelected,
          enabled: item.enabled,
          colors: colors,
          typography: typography,
          brightness: brightness,
        ),
        activeItem: _AnimatedNavIcon(
          asset: item.iconAsset,
          label: item.label,
          semanticLabel: item.semanticLabel,
          selected: true,
          enabled: item.enabled,
          colors: colors,
          typography: typography,
          brightness: brightness,
        ),
        itemLabelWidget: _AnimatedNavLabel(
          label: item.label,
          selected: isSelected,
          enabled: item.enabled,
          colors: colors,
          typography: typography,
          brightness: brightness,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final brightness = Theme.of(context).brightness;

    return MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1,
      child:       SafeArea(
        top: false,
        child: SizedBox(
          height: BottomNavTokens.bottomBarHeight + 29,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              // Base notch bar
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: AnimatedNotchBottomBar(
                  notchBottomBarController: widget.controller,
                  bottomBarItems: _buildBarItems(),
                  onTap: _handleTap,
                  color: BottomNavTokens.backgroundColor(colors, brightness),
                  notchColor: BottomNavTokens.notchColor(colors, brightness),
                  durationInMilliSeconds:
                      BottomNavTokens.durationInMilliSeconds,
                  bottomBarHeight: BottomNavTokens.bottomBarHeight,
                  kBottomRadius: BottomNavTokens.kBottomRadius,
                  showTopRadius: BottomNavTokens.showTopRadius,
                  showBottomRadius: BottomNavTokens.showBottomRadius,
                  removeMargins: BottomNavTokens.removeMargins,
                  elevation: BottomNavTokens.elevation,
                  shadowElevation: BottomNavTokens.elevation,
                  showShadow: BottomNavTokens.showShadow(brightness),
                  showBlurBottomBar: BottomNavTokens.showBlurBottomBar,
                  blurOpacity: BottomNavTokens.blurOpacity,
                  blurFilterX: BottomNavTokens.blurFilterX,
                  blurFilterY: BottomNavTokens.blurFilterY,
                  kIconSize: BottomNavTokens.kIconSize,
                  topMargin: BottomNavTokens.topMargin,
                  circleMargin: BottomNavTokens.circleMargin,
                  showLabel: BottomNavTokens.showLabel,
                ),
              ),

              // Center floating action button overlay
              Positioned(
                top: 0,
                child: _CenterActionButton(
                  action: widget.centerAction,
                  colors: colors,
                  brightness: brightness,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated icon for navigation items.
class _AnimatedNavIcon extends StatelessWidget {
  const _AnimatedNavIcon({
    required this.asset,
    required this.label,
    required this.semanticLabel,
    required this.selected,
    required this.enabled,
    required this.colors,
    required this.typography,
    required this.brightness,
  });

  final String asset;
  final String label;
  final String? semanticLabel;
  final bool selected;
  final bool enabled;
  final AppColors colors;
  final AppTypography typography;
  final Brightness brightness;

  Color get _iconColor {
    if (!enabled) {
      return BottomNavTokens.disabledIconColor(colors);
    }
    return selected
        ? BottomNavTokens.selectedIconColor(colors)
        : BottomNavTokens.unselectedIconColor(colors, brightness);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? label,
      button: true,
      enabled: enabled,
      selected: selected,
      child:       AnimatedScale(
        scale: selected ? BottomNavTokens.selectedIconScale : 1,
        duration: Duration(
          milliseconds: BottomNavTokens.durationInMilliSeconds,
        ),
        curve: BottomNavTokens.animationCurve,
        child: AnimatedOpacity(
          opacity: selected ? 1 : BottomNavTokens.unselectedIconOpacity,
          duration: Duration(
            milliseconds: BottomNavTokens.durationInMilliSeconds,
          ),
          curve: BottomNavTokens.animationCurve,
          child: AppSvgPicture.asset(
            asset,
            width: BottomNavTokens.kIconSize,
            height: BottomNavTokens.kIconSize,
            colorFilter: ColorFilter.mode(_iconColor, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}

/// Animated label for navigation items.
class _AnimatedNavLabel extends StatelessWidget {
  const _AnimatedNavLabel({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.colors,
    required this.typography,
    required this.brightness,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final AppColors colors;
  final AppTypography typography;
  final Brightness brightness;

  TextStyle get _textStyle {
    if (!enabled) {
      return BottomNavTokens.disabledLabelStyle(typography, colors);
    }
    return selected
        ? BottomNavTokens.selectedLabelStyle(typography, colors)
        : BottomNavTokens.unselectedLabelStyle(
            typography,
            colors,
            brightness,
          );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: selected ? 1 : BottomNavTokens.unselectedIconOpacity,
      duration: Duration(
        milliseconds: BottomNavTokens.durationInMilliSeconds,
      ),
      curve: BottomNavTokens.animationCurve,
      child: Text(
        label,
        style: _textStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Center floating action button.
class _CenterActionButton extends StatelessWidget {
  const _CenterActionButton({
    required this.action,
    required this.colors,
    required this.brightness,
  });

  final AppBottomNavCenterAction action;
  final AppColors colors;
  final Brightness brightness;

  Color get _fabColor {
    if (!action.enabled) {
      return BottomNavTokens.centerFabDisabledColor(colors);
    }
    return action.selected
        ? BottomNavTokens.centerFabActiveColor(colors, brightness)
        : BottomNavTokens.centerFabInactiveColor(colors);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = action.enabled && action.onTap != null;

    return Semantics(
      button: true,
      enabled: enabled,
      label: action.semanticLabel,
      child:       AnimatedScale(
        scale: action.selected ? 1.06 : 1,
        duration: Duration(
          milliseconds: BottomNavTokens.durationInMilliSeconds,
        ),
        curve: BottomNavTokens.animationCurve,
        child: Material(
          color: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? action.onTap : null,
            customBorder: const CircleBorder(),
            splashColor: BottomNavTokens.centerFabIconColor(colors)
                .withValues(alpha: 0.12),
            highlightColor: BottomNavTokens.centerFabActiveColor(
              colors,
              brightness,
            ).withValues(alpha: 0.24),
            child: AnimatedContainer(
              duration: Duration(
                milliseconds: BottomNavTokens.durationInMilliSeconds,
              ),
              curve: BottomNavTokens.animationCurve,
              width: BottomNavTokens.centerFabSize,
              height: BottomNavTokens.centerFabSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _fabColor,
                border: Border.all(
                  color: BottomNavTokens.centerFabBorderColor(colors),
                  width: 2,
                ),
                boxShadow: enabled ? BottomNavTokens.centerFabShadow : null,
              ),
              child: Center(
                child: AnimatedOpacity(
                  opacity: enabled ? 1 : 0.5,
                  duration: Duration(
                    milliseconds: BottomNavTokens.durationInMilliSeconds,
                  ),
                  curve: BottomNavTokens.animationCurve,
                  child: AppSvgPicture.asset(
                    action.iconAsset,
                    width: BottomNavTokens.kIconSize,
                    height: BottomNavTokens.kIconSize,
                    colorFilter: ColorFilter.mode(
                      BottomNavTokens.centerFabIconColor(colors),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
