import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// A dimming overlay + progress bar shown over a media slot while a feature's
/// upload/removal is in flight. Rendering only — the busy state and [progress]
/// are supplied by the consuming feature (the package itself never uploads).
class MediaBusyOverlay extends StatelessWidget {
  const MediaBusyOverlay({
    required this.progress,
    this.borderRadius,
    super.key,
  });

  /// Transfer progress `0.0`–`1.0`.
  final double progress;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.45),
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: AppProgressBar(value: progress),
            ),
          ),
        ),
      ),
    );
  }
}
