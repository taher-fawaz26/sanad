import 'package:app_assets/app_assets.dart';
import 'package:design_system/src/components/app_svg_picture.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/tokens/alert_tokens.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';

/// Figma inline `Alert` banner (`3821:19134` – `3821:19202`).
///
/// View-only status message with leading icon, soft fill, and semantic border.
/// Supports warning, error, info, and rejected variants.
class AppAlert extends StatelessWidget {
  const AppAlert({
    required this.message,
    required this.type,
    super.key,
    this.icon,
  });

  final String message;
  final AppAlertType type;

  /// Optional icon override. Defaults to the Figma icon for [type].
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final brightness = Theme.of(context).brightness;
    final spec = AlertTokens.resolve(
      type: type,
      typography: typography,
      colors: colors,
      brightness: brightness,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: spec.backgroundColor,
        borderRadius: spec.borderRadius,
        border: Border.all(
          color: spec.borderColor,
          width: spec.borderWidth,
        ),
      ),
      child: Padding(
        padding: spec.padding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: spec.iconSize,
              height: spec.iconSize,
              child:
                  icon ??
                  AppSvgPicture.asset(
                    _iconAssetFor(type),
                    width: spec.iconSize,
                    height: spec.iconSize,
                    colorFilter: ColorFilter.mode(
                      spec.iconColor,
                      BlendMode.srcIn,
                    ),
                  ),
            ),
            SizedBox(width: spec.contentGap),
            Expanded(
              child: Text(
                message,
                style: spec.textStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _iconAssetFor(AppAlertType type) => switch (type) {
    AppAlertType.warning => AppSvgs.alertTriangle,
    AppAlertType.error => AppSvgs.alertCircle,
    AppAlertType.info || AppAlertType.rejected => AppSvgs.reloadWindow,
  };
}
