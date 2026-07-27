import 'dart:io';

import 'package:asset_picker/src/domain/entities/picked_asset.dart';
import 'package:asset_picker/src/domain/enums/asset_type.dart';
import 'package:asset_picker/src/presentation/widgets/asset_thumbnail.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Invoked when the user asks to open an asset the preview cannot render inline
/// (e.g. a PDF or arbitrary file). The package stays generic — it does not
/// launch anything itself; the host decides how to open the asset.
typedef AssetOpenCallback = void Function(PickedAsset asset);

/// Builds a fully custom preview body for an asset. Use it to inject a real
/// in-app renderer (e.g. a PDF viewer) without the package taking on that
/// dependency.
typedef AssetPreviewBuilder =
    Widget Function(
      BuildContext context,
      PickedAsset asset,
    );

/// The shared, type-aware body used by both `AssetPreviewPage` and
/// `AssetPreviewDialog`.
///
/// It picks how to render the asset automatically from its [AssetType]:
/// * **Image** → zoomable, pan-able view (via [InteractiveViewer]).
/// * **Anything else** (PDF, document, unknown) → a document card built from
///   [AssetThumbnail] with name, size, and an optional "Open" action.
///
/// A [previewBuilder] override wins for non-image types, so a host can plug in
/// a genuine PDF renderer while everything else keeps the default behaviour.
class AssetPreviewContent extends StatelessWidget {
  const AssetPreviewContent({
    required this.asset,
    this.onOpen,
    this.previewBuilder,
    this.openLabel = 'Open',
    super.key,
  });

  final PickedAsset asset;
  final AssetOpenCallback? onOpen;
  final AssetPreviewBuilder? previewBuilder;
  final String openLabel;

  bool get _isRenderableImage =>
      asset.assetType == AssetType.image &&
      (asset.bytes != null || (!kIsWeb && asset.path.isNotEmpty));

  @override
  Widget build(BuildContext context) {
    if (_isRenderableImage) return _buildImage(context);
    if (previewBuilder != null) return previewBuilder!(context, asset);
    return _buildDocumentCard(context);
  }

  Widget _buildImage(BuildContext context) {
    Widget errorBuilder(
      BuildContext context,
      Object error,
      StackTrace? stack,
    ) => _buildDocumentCard(context);

    final image = asset.bytes != null
        ? Image.memory(asset.bytes!, errorBuilder: errorBuilder)
        : Image.file(File(asset.path), errorBuilder: errorBuilder);

    return InteractiveViewer(
      maxScale: 5,
      child: Center(child: image),
    );
  }

  Widget _buildDocumentCard(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AssetThumbnail(
              asset: asset,
              size: 96,
              borderRadius: AppRadius.circularLg,
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              asset.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: typography.largeNormal.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              _formatSize(asset.size),
              style: typography.smallNormal.copyWith(
                color: colors.textSecondary,
              ),
            ),
            if (onOpen != null) ...[
              SizedBox(height: AppSpacing.lg),
              AppButtonPresets.outline(
                label: openLabel,
                onPressed: () => onOpen!(asset),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatSize(int bytes) {
    if (bytes <= 0) return '';
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }
}
