import 'dart:io';

import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/entities/ai_chat_attachment.dart';

/// One staged attachment in the composer.
///
/// Temporary UI: functional, built from design-system tokens, and deliberately
/// not the final design. It is a leaf widget — it holds no state, runs no async
/// work, touches no plugin and reads nothing from the service locator. It takes
/// a value and a callback.
class AiAttachmentTile extends StatelessWidget {
  /// Creates a tile for [attachment].
  const AiAttachmentTile({
    required this.attachment,
    required this.onRemove,
    super.key,
    this.size = 64,
  });

  /// What to draw.
  final AiChatAttachment attachment;

  /// Called when the user taps the remove affordance.
  final VoidCallback onRemove;

  /// Tile edge length.
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: AppRadius.circularSm,
                border: Border.all(color: colors.border),
              ),
              child: ClipRRect(
                borderRadius: AppRadius.circularSm,
                child: _Preview(attachment: attachment, size: size),
              ),
            ),
          ),
          if (attachment.status.isBusy)
            Positioned.fill(
              child: ColoredBox(
                color: colors.background.withValues(alpha: 0.6),
                child: const Center(child: AppLoadingIndicator(size: 16)),
              ),
            ),
          PositionedDirectional(
            top: 0,
            end: 0,
            child: GestureDetector(
              onTap: onRemove,
              child: Semantics(
                button: true,
                label: 'ai_chat.remove_attachment'.tr(),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: colors.textPrimary.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: colors.background,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.attachment, required this.size});

  final AiChatAttachment attachment;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return switch (attachment) {
      AiImageAttachment() => Image.file(
        File(attachment.localPath),
        fit: BoxFit.cover,
        width: size,
        height: size,
        // Decoded at tile resolution rather than full size. This is why the
        // model carries no thumbnail path: a 12-megapixel photo never becomes
        // a 48 MB bitmap just to fill a 64-point square.
        cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
        // A file that vanished under us must not take the composer with it.
        errorBuilder: (context, _, _) =>
            Icon(Icons.broken_image_outlined, color: colors.textSecondary),
      ),
      AiDocumentAttachment(:final extension) => _DocumentPreview(
        extension: extension,
      ),
      AiAudioAttachment(:final duration) => _AudioPreview(duration: duration),
    };
  }
}

class _DocumentPreview extends StatelessWidget {
  const _DocumentPreview({required this.extension});

  final String extension;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return _TileLabel(
      icon: Icons.description_outlined,
      iconColor: colors.textSecondary,
      label: extension.toUpperCase(),
    );
  }
}

class _AudioPreview extends StatelessWidget {
  const _AudioPreview({required this.duration});

  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return _TileLabel(
      icon: Icons.graphic_eq_rounded,
      iconColor: context.appColors.primary,
      label: formatClock(duration),
    );
  }
}

/// An icon over a short label, inside a fixed-size tile.
///
/// `MainAxisSize.min` plus a `FittedBox` on the label, because the tile is a
/// hard 64 points and the label's height follows the user's text-scale factor:
/// without both, a large accessibility text size overflows the tile. The
/// widget test that caught this asserts the layout, not just the content.
class _TileLabel extends StatelessWidget {
  const _TileLabel({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: iconColor),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: context.appTypography.smallNormal.copyWith(
                color: context.appColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// `m:ss`, the way a voice note reads everywhere else in the app.
///
/// Digits are forced LTR: under an Arabic layout a bidi-neutral colon between
/// two numbers otherwise lets the clock render back to front.
String formatClock(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}'.ltrIsolated;
}
