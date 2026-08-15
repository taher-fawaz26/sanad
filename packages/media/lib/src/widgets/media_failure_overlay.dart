import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// A dimming overlay shown over a media slot after its upload failed —
/// mirrors the dimming treatment of [MediaBusyOverlay] and the failure
/// overlay used by the `media_upload` grid tiles. Rendering only — the
/// consuming feature supplies [errorMessage] and [onRetry].
class MediaFailureOverlay extends StatelessWidget {
  const MediaFailureOverlay({
    this.errorMessage,
    this.onRetry,
    this.borderRadius,
    super.key,
  });

  final String? errorMessage;
  final VoidCallback? onRetry;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Positioned.fill(
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.55),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: colors.palettes.red.shade500,
                  ),
                  if (errorMessage != null) ...[
                    SizedBox(height: AppSpacing.xs),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: context.appTypography.smallNormal.copyWith(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                  if (onRetry != null) ...[
                    SizedBox(height: AppSpacing.xs),
                    Semantics(
                      button: true,
                      label: 'media.retry_upload_a11y'.tr(),
                      child: InkWell(
                        onTap: onRetry,
                        child: const Icon(
                          Icons.refresh,
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
