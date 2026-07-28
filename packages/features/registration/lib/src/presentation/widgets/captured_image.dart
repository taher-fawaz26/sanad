import 'dart:io';

import 'package:asset_picker/asset_picker.dart';
import 'package:flutter/material.dart';

/// Renders a captured [PickedAsset] as an image, preferring in-memory bytes
/// (available on some platforms) and falling back to the file path.
///
/// Non-image assets (e.g. a PDF trade licence) have no inline preview, so
/// [fallback] is shown instead.
class CapturedImage extends StatelessWidget {
  const CapturedImage({
    required this.asset,
    super.key,
    this.fit = BoxFit.cover,
    this.fallback,
  });

  final PickedAsset asset;
  final BoxFit fit;
  final Widget? fallback;

  bool get _isImage => asset.mimeType.startsWith('image/');

  @override
  Widget build(BuildContext context) {
    if (!_isImage) {
      return fallback ?? const SizedBox.shrink();
    }
    if (asset.hasBytes) {
      return Image.memory(asset.bytes!, fit: fit);
    }
    if (asset.path.isNotEmpty) {
      return Image.file(File(asset.path), fit: fit);
    }
    return fallback ?? const SizedBox.shrink();
  }
}
