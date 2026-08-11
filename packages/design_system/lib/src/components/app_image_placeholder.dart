import 'package:app_assets/app_assets.dart';
import 'package:design_system/src/components/app_svg_picture.dart';
import 'package:flutter/material.dart';

/// Default image placeholder for missing URLs and failed network loads.
///
/// Uses the shared `image_placeholder` SVG from `app_assets` and scales to
/// [width] × [height] or expands to fill the parent when dimensions are null.
class AppImagePlaceholder extends StatelessWidget {
  const AppImagePlaceholder({
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    Widget child = AppSvgPicture.asset(
      AppSvgs.imagePlaceholder,
      width: width,
      height: height,
      fit: fit,
    );

    if (width == null && height == null) {
      child = SizedBox.expand(child: child);
    }

    if (borderRadius != null) {
      child = ClipRRect(borderRadius: borderRadius!, child: child);
    }

    return child;
  }
}
