import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import 'package:shared_widgets/src/components/app_svg_picture.dart';

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
