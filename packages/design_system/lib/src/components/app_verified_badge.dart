import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:flutter/material.dart';

/// Figma verified label badge (`3784:17466`) — 16 px primary disc + check.
class AppVerifiedBadge extends StatelessWidget {
  const AppVerifiedBadge({super.key});

  static const double _size = 16;
  static const double _iconSize = 10;

  @override
  Widget build(BuildContext context) {
    final color = context.appColors.primary;

    return DecoratedBox(
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: SizedBox(
        width: _size,
        height: _size,
        child: Icon(Icons.check, size: _iconSize, color: context.appColors.onPrimary),
      ),
    );
  }
}
