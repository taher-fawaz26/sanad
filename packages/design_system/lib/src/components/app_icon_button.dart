import 'package:app_assets/app_assets.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/tokens/button_tokens.dart';
import 'package:design_system/src/theme/tokens/icon_button_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Figma `icon buttons` (`62:731`).
///
/// [semanticLabel] is required — an icon-only control has no accessible name
/// on its own, so callers must supply one.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    required this.onTap,
    required this.semanticLabel,
    super.key,
    this.icon,
    this.iconAsset,
    this.size = AppIconButtonSize.small,
    this.intent = AppButtonIntent.standard,
    this.iconColor,
  }) : assert(
         icon != null || iconAsset != null,
         'Provide either icon or iconAsset.',
       );

  final VoidCallback? onTap;
  final IconData? icon;
  final String? iconAsset;
  final AppIconButtonSize size;
  final AppButtonIntent intent;
  final Color? iconColor;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final spec = IconButtonTokens.resolve(
      size: size,
      colors: context.appColors,
      intent: intent,
      iconColor: iconColor,
    );

    Widget iconWidget;
    if (iconAsset != null) {
      iconWidget = SvgPicture.asset(
        iconAsset!,
        package: AppAssets.package,
        width: spec.iconSize,
        height: spec.iconSize,
        colorFilter: ColorFilter.mode(spec.iconColor, BlendMode.srcIn),
      );
    } else {
      iconWidget = Icon(
        icon,
        size: spec.iconSize,
        color: spec.iconColor,
      );
    }

    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: onTap != null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: spec.borderRadius,
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          child: SizedBox(
            width: spec.size,
            height: spec.size,
            child: Center(child: iconWidget),
          ),
        ),
      ),
    );
  }
}
