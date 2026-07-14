import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/tokens/nav_bar_tokens.dart';
import 'package:flutter/material.dart';

/// Figma `Bars / Nav Bars` (`40:6839`).
class AppNavBar extends StatelessWidget implements PreferredSizeWidget {
  const AppNavBar({
    required this.title,
    super.key,
    this.leading,
    this.leadingLabel,
    this.onLeadingTap,
    this.showBackButton = false,
    this.trailing,
    this.trailingLabel,
    this.onTrailingTap,
    this.trailingAction = AppNavBarTrailingAction.none,
    this.trailingButtonLabel,
    this.onTrailingButtonTap,
  });

  final String title;
  final Widget? leading;
  final String? leadingLabel;
  final VoidCallback? onLeadingTap;
  final bool showBackButton;
  final Widget? trailing;
  final String? trailingLabel;
  final VoidCallback? onTrailingTap;
  final AppNavBarTrailingAction trailingAction;
  final String? trailingButtonLabel;
  final VoidCallback? onTrailingButtonTap;

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spec = context.appNavBarTheme.standard;
    final height = trailingAction == AppNavBarTrailingAction.button
        ? spec.heightWithButton
        : spec.height;

    return Material(
      color: spec.backgroundColor,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: height,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: spec.horizontalPadding,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  title,
                  style: spec.titleStyle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    _buildLeading(context, spec, colors),
                    const Spacer(),
                    _buildTrailing(context, spec, colors),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeading(
    BuildContext context,
    StandardNavBarStyleSpec spec,
    AppColors colors,
  ) {
    if (leading != null) {
      return GestureDetector(
        onTap: onLeadingTap,
        child: leading,
      );
    }

    if (showBackButton || leadingLabel != null) {
      return GestureDetector(
        onTap: onLeadingTap,
        behavior: HitTestBehavior.opaque,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showBackButton)
              Icon(
                Icons.chevron_left,
                size: spec.iconSize,
                color: spec.actionTextStyle.color,
              ),
            if (showBackButton && leadingLabel != null)
              SizedBox(width: spec.leadingIconTextGap),
            if (leadingLabel != null)
              Text(leadingLabel!, style: spec.actionTextStyle),
          ],
        ),
      );
    }

    if (leadingLabel != null && !showBackButton) {
      return GestureDetector(
        onTap: onLeadingTap,
        child: Text(leadingLabel!, style: spec.actionTextStyle),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildTrailing(
    BuildContext context,
    StandardNavBarStyleSpec spec,
    AppColors colors,
  ) {
    return switch (trailingAction) {
      AppNavBarTrailingAction.none => const SizedBox.shrink(),
      AppNavBarTrailingAction.text => GestureDetector(
        onTap: onTrailingTap,
        child: Text(
          trailingLabel ?? '',
          style: spec.actionTextStyle,
        ),
      ),
      AppNavBarTrailingAction.icon => GestureDetector(
        onTap: onTrailingTap,
        child:
            trailing ??
            Icon(
              Icons.settings_outlined,
              size: spec.iconSize,
              color: colors.primary,
            ),
      ),
      AppNavBarTrailingAction.button => GestureDetector(
        onTap: onTrailingButtonTap,
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
    };
  }
}
