import 'package:asset_picker/src/domain/entities/picked_asset.dart';
import 'package:asset_picker/src/presentation/preview/asset_preview_content.dart';
import 'package:asset_picker/src/presentation/preview/asset_preview_dialog.dart';
import 'package:asset_picker/src/presentation/preview/asset_preview_page.dart';
import 'package:flutter/material.dart';

/// Ergonomic entry point for previewing assets.
///
/// A thin, stateless facade over [AssetPreviewDialog] and [AssetPreviewPage] —
/// it holds no logic beyond choosing a sensible presentation. It is fully
/// generic: no business behaviour, no networking.
///
/// ```dart
/// // Quick single-asset dialog:
/// await AssetPreview.show(context, asset: myAsset);
///
/// // Full-screen, swipeable gallery:
/// await AssetPreview.show(context, assets: myAssets, asPage: true);
/// ```
abstract final class AssetPreview {
  AssetPreview._();

  /// Presents a preview. Supply either a single [asset] or a list of [assets].
  ///
  /// Presents a full-screen [AssetPreviewPage] when [asPage] is set or when
  /// more than one asset is given; otherwise a compact [AssetPreviewDialog].
  static Future<void> show(
    BuildContext context, {
    PickedAsset? asset,
    List<PickedAsset>? assets,
    int initialIndex = 0,
    AssetOpenCallback? onOpen,
    AssetPreviewBuilder? previewBuilder,
    String? title,
    bool asPage = false,
  }) {
    assert(
      asset != null || (assets != null && assets.isNotEmpty),
      'Provide either a single asset or a non-empty assets list.',
    );
    final items = assets ?? [asset!];

    if (asPage || items.length > 1) {
      return openPage(
        context,
        assets: items,
        initialIndex: initialIndex,
        onOpen: onOpen,
        previewBuilder: previewBuilder,
        title: title,
      );
    }

    return showDialog<void>(
      context: context,
      builder: (_) => AssetPreviewDialog(
        asset: items.first,
        onOpen: onOpen,
        previewBuilder: previewBuilder,
        title: title,
      ),
    );
  }

  /// Pushes a full-screen [AssetPreviewPage] onto the navigator.
  static Future<void> openPage(
    BuildContext context, {
    required List<PickedAsset> assets,
    int initialIndex = 0,
    AssetOpenCallback? onOpen,
    AssetPreviewBuilder? previewBuilder,
    String? title,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AssetPreviewPage(
          assets: assets,
          initialIndex: initialIndex,
          onOpen: onOpen,
          previewBuilder: previewBuilder,
          title: title,
        ),
      ),
    );
  }
}
