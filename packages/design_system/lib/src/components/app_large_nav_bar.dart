import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/tokens/nav_bar_tokens.dart';
import 'package:flutter/material.dart';

/// Figma `Bars / Nav Bars: Large` (`40:6931`).
class AppLargeNavBar extends StatelessWidget implements PreferredSizeWidget {
  const AppLargeNavBar({
    required this.title, super.key,
    this.caption,
    this.trailingAction = AppNavBarTrailingAction.none,
    this.trailing,
    this.trailingButtonLabel,
    this.onTrailingTap,
    this.useLargeTitleStyle = false,
  });

  final String title;
  final String? caption;
  final AppNavBarTrailingAction trailingAction;
  final Widget? trailing;
  final String? trailingButtonLabel;
  final VoidCallback? onTrailingTap;
  final bool useLargeTitleStyle;

  bool get _hasCaption => caption != null && caption!.isNotEmpty;

  @override
  Size get preferredSize {
    final height = _hasCaption ? 92.0 : 60.0;
    return Size.fromHeight(height);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spec = context.appNavBarTheme.large;
    final height = _hasCaption ? spec.heightExpanded : spec.heightCompact;
    final titleRightInset = switch (trailingAction) {
      AppNavBarTrailingAction.icon => spec.titleRightInsetIcon,
      AppNavBarTrailingAction.button => spec.titleRightInsetButton,
      _ => 0.0,
    };

    final titleStyle = useLargeTitleStyle && _hasCaption
        ? spec.titleStyleLarge
        : spec.titleStyle;

    return Material(
      color: spec.backgroundColor,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: height,
          child: Stack(
            children: [
              Positioned(
                left: spec.horizontalPadding,
                right: spec.horizontalPadding + titleRightInset,
                top: _hasCaption ? height / 2 - 34 : null,
                bottom: _hasCaption ? null : 0,
                child: _hasCaption
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(title, style: titleStyle),
                          const SizedBox(height: 8),
                          Text(caption!, style: spec.captionStyle),
                        ],
                      )
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: Text(title, style: titleStyle),
                      ),
              ),
              if (trailingAction != AppNavBarTrailingAction.none)
                Positioned(
                  right: trailingAction == AppNavBarTrailingAction.icon
                      ? spec.trailingIconInset
                      : spec.trailingButtonInset,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _buildTrailing(spec, colors),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrailing(LargeNavBarStyleSpec spec, AppColors colors) {
    return switch (trailingAction) {
      AppNavBarTrailingAction.icon => GestureDetector(
          onTap: onTrailingTap,
          child: trailing ??
              Icon(
                Icons.person_outline,
                size: spec.iconSize,
                color: colors.primary,
              ),
        ),
      AppNavBarTrailingAction.button => GestureDetector(
          onTap: onTrailingTap,
          child: Container(
            padding: spec.actionButtonPadding,
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: spec.actionButtonRadius,
            ),
            child: Text(
              trailingButtonLabel ?? 'Button',
              style: spec.actionButtonTextStyle,
            ),
          ),
        ),
      _ => const SizedBox.shrink(),
    };
  }
}
