import 'package:app_assets/app_assets.dart';
import 'package:design_system/src/components/app_svg_picture.dart';
import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:flutter/material.dart';

/// Close (X) icon button — Figma nav dismiss (`194:4058`).
class AppCloseIcon extends StatelessWidget {
  const AppCloseIcon({
    super.key,
    this.onTap,
    this.size,
  });

  final VoidCallback? onTap;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final iconSize = size ?? AppDimension.iconLg;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AppSvgPicture.asset(
        AppSvgs.close,
        width: iconSize,
        height: iconSize,
      ),
    );
  }
}
