import 'dart:io';

import 'package:asset_picker/src/domain/entities/picked_asset.dart';
import 'package:asset_picker/src/domain/enums/asset_type.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// The Material glyph representing an [AssetType] when no image preview is
/// available. Shared so thumbnails and previews stay visually consistent.
IconData assetTypeGlyph(AssetType type) => switch (type) {
  AssetType.image => Icons.image_outlined,
  AssetType.video => Icons.videocam_outlined,
  AssetType.audio => Icons.audiotrack_outlined,
  AssetType.pdf => Icons.picture_as_pdf_outlined,
  AssetType.document => Icons.description_outlined,
  AssetType.any => Icons.insert_drive_file_outlined,
};

/// A reusable, type-aware thumbnail for any [PickedAsset].
///
/// It removes duplicated "what icon / preview do I show for this file?" logic
/// from features. It automatically renders:
///
/// * **Image** → the actual image (from bytes or file path), cropped to fit.
/// * **PDF** → a PDF glyph on a tinted surface.
/// * **Document** (Word/Excel/…) → a document glyph.
/// * **Unknown / other** → a generic file glyph.
///
/// Everything is design-system driven with sensible defaults, and every visual
/// aspect is overridable ([size], [borderRadius], [backgroundColor], [fit],
/// [placeholder], [iconColor]).
class AssetThumbnail extends StatelessWidget {
  const AssetThumbnail({
    required this.asset,
    this.size = 48,
    this.borderRadius,
    this.backgroundColor,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.iconColor,
    super.key,
  });

  /// The asset to represent.
  final PickedAsset asset;

  /// Width and height of the (square) thumbnail.
  final double size;

  /// Corner radius. Defaults to [AppRadius.circularMd].
  final BorderRadius? borderRadius;

  /// Background behind icon thumbnails. Defaults to the selected-container
  /// tint.
  final Color? backgroundColor;

  /// How an image thumbnail is inscribed into its box.
  final BoxFit fit;

  /// Shown while / instead of an image that cannot be resolved. Defaults to the
  /// type glyph.
  final Widget? placeholder;

  /// Glyph color for non-image thumbnails. Defaults to the primary color.
  final Color? iconColor;

  bool get _isRenderableImage =>
      asset.assetType == AssetType.image &&
      (asset.bytes != null || (!kIsWeb && asset.path.isNotEmpty));

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = borderRadius ?? AppRadius.circularMd;
    final background = backgroundColor ?? colors.selectedContainer;

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: size,
        height: size,
        child: _isRenderableImage
            ? _buildImage(context, background)
            : _buildIcon(context, background),
      ),
    );
  }

  Widget _buildImage(BuildContext context, Color background) {
    Widget errorBuilder(
      BuildContext context,
      Object error,
      StackTrace? stack,
    ) => _buildIcon(context, background);

    if (asset.bytes != null) {
      return Image.memory(asset.bytes!, fit: fit, errorBuilder: errorBuilder);
    }
    return Image.file(File(asset.path), fit: fit, errorBuilder: errorBuilder);
  }

  Widget _buildIcon(BuildContext context, Color background) {
    final colors = context.appColors;
    return ColoredBox(
      color: background,
      child: Center(
        child:
            placeholder ??
            Icon(
              assetTypeGlyph(asset.assetType),
              size: size * 0.5,
              color: iconColor ?? colors.primary,
            ),
      ),
    );
  }
}
