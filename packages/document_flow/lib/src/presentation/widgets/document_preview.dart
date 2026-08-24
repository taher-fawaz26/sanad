import 'dart:io';

import 'package:asset_picker/asset_picker.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Renders a captured [PickedAsset] as an image, preferring in-memory bytes
/// (available on some platforms), then the local file path, then [remoteUrl]
/// — the last case covers a prefilled slot for an already-stored document
/// (e.g. a renewal flow's `enablePrefetch`), which has neither bytes nor a
/// local path since the file was never picked on this device.
///
/// Non-image assets (e.g. a PDF trade licence) have no inline preview, so
/// [fallback] is shown instead.
class DocumentPreview extends StatelessWidget {
  const DocumentPreview({
    required this.asset,
    super.key,
    this.fit = BoxFit.cover,
    this.fallback,
    this.remoteUrl,
  });

  final PickedAsset asset;
  final BoxFit fit;
  final Widget? fallback;

  /// The backend-hosted URL for this document, when this slot was prefilled
  /// rather than picked on-device. `AppNetworkImage` already shows a shimmer
  /// while loading and a graceful placeholder if the URL fails to resolve
  /// (e.g. an unreachable seed/test host), so no extra handling is needed
  /// here beyond preferring it over [fallback].
  final String? remoteUrl;

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
    final url = remoteUrl;
    if (url != null && url.isNotEmpty) {
      return AppNetworkImage(url, fit: fit);
    }
    return fallback ?? const SizedBox.shrink();
  }
}
