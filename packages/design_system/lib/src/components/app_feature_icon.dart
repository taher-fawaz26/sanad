import 'package:core/core.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/tokens/feature_icon_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Figma `Featured Icon` (`751:4005`).
///
/// Circular status / brand icon with optional outer ring.
/// Defaults to the Figma glyph for [color] (zap / alert / check); pass
/// [iconAsset] to override.
class AppFeatureIcon extends StatelessWidget {
  const AppFeatureIcon({
    super.key,
    this.color = AppFeatureIconColor.primary,
    this.size = AppFeatureIconSize.md,
    this.theme = AppFeatureIconTheme.lightCircle,
    this.iconAsset,
  });

  final AppFeatureIconColor color;
  final AppFeatureIconSize size;
  final AppFeatureIconTheme theme;

  /// Optional SVG asset path. Defaults to the Figma glyph for [color].
  ///
  /// Prefer [AppSvgs] paths with `SvgPicture.asset(..., package: AppAssets.package)`.
  final String? iconAsset;

  @override
  Widget build(BuildContext context) {
    final spec = FeatureIconTokens.resolve(
      size: size,
      color: color,
      theme: theme,
      colors: context.appColors,
    );

    final hasOutline = theme == AppFeatureIconTheme.lightCircleOutline;

    return SizedBox(
      width: spec.containerSize,
      height: spec.containerSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: spec.backgroundColor,
          shape: BoxShape.circle,
          border: hasOutline
              ? Border.all(
                  color: spec.outlineColor,
                  width: spec.outlineBorderWidth,
                )
              : null,
        ),
        child: Center(
          child: SvgPicture.asset(
            iconAsset ?? spec.defaultIconAsset,
            package: AppAssets.package,
            width: spec.iconSize,
            height: spec.iconSize,
            colorFilter: ColorFilter.mode(
              spec.iconColor,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}
