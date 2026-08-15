import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// A dimming overlay + progress bar shown over a media slot while a feature's
/// upload/removal is in flight. Rendering only — the busy state and [progress]
/// are supplied by the consuming feature (the package itself never uploads).
///
/// When [onCancel] is supplied, a small cancel affordance is shown below the
/// progress bar — mirrors the remove-cancels-in-flight-upload pattern used by
/// the `media_upload` grid tiles.
class MediaBusyOverlay extends StatelessWidget {
  const MediaBusyOverlay({
    required this.progress,
    this.borderRadius,
    this.onCancel,
    super.key,
  });

  /// Transfer progress `0.0`–`1.0`.
  final double progress;
  final BorderRadius? borderRadius;
  final VoidCallback? onCancel;

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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppProgressBar(value: progress),
                  if (onCancel != null) ...[
                    SizedBox(height: AppSpacing.xs),
                    Semantics(
                      button: true,
                      label: 'media.cancel_upload_a11y'.tr(),
                      child: InkWell(
                        onTap: onCancel,
                        child: const Icon(
                          Icons.close,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
