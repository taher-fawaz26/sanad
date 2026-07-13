import 'package:app_assets/app_assets.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Loads SVG assets from the `app_assets` package.
abstract final class AppSvgPicture {
  AppSvgPicture._();

  /// Renders an SVG from [AppSvgs] using [AppAssets.package].
  static Widget asset(
    String assetPath, {
    double? width,
    double? height,
    ColorFilter? colorFilter,
    BoxFit fit = BoxFit.contain,
  }) {
    return SvgPicture.asset(
      assetPath,
      package: AppAssets.package,
      width: width,
      height: height,
      colorFilter: colorFilter,
      fit: fit,
    );
  }
}
