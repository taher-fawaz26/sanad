import 'package:asset_picker/src/domain/entities/picked_asset.dart';
import 'package:asset_picker/src/presentation/preview/asset_preview_content.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// A compact, generic preview dialog for a single asset.
///
/// Uses the design-system surface and radius, with a close affordance and the
/// shared [AssetPreviewContent] body. For full-screen or multi-asset previews
/// use `AssetPreviewPage` instead.
class AssetPreviewDialog extends StatelessWidget {
  const AssetPreviewDialog({
    required this.asset,
    this.onOpen,
    this.previewBuilder,
    this.title,
    super.key,
  });

  final PickedAsset asset;
  final AssetOpenCallback? onOpen;
  final AssetPreviewBuilder? previewBuilder;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final media = MediaQuery.sizeOf(context);

    return Dialog(
      backgroundColor: colors.surface,
      insetPadding: EdgeInsets.all(AppSpacing.xl),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.circularLg),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: media.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title ?? asset.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: typography.largeNormal.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  AppCloseIcon(onTap: () => Navigator.of(context).maybePop()),
                ],
              ),
            ),
            Flexible(
              child: AssetPreviewContent(
                asset: asset,
                onOpen: onOpen,
                previewBuilder: previewBuilder,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
