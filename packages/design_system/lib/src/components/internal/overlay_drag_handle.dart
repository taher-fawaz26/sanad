import 'package:flutter/material.dart';

/// Shared native-chrome drag-handle indicator, used by [AppBackdrop].
///
/// Figma `Native / Bottom Sheet Indicator` (`40:8321`).
class OverlayDragHandle extends StatelessWidget {
  const OverlayDragHandle({
    required this.width,
    required this.height,
    required this.color,
    super.key,
  });

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(height / 2),
        ),
      ),
    );
  }
}
