import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/src/rendering/ai_ui_render_scope.dart';
import 'package:ai_ui_renderer/src/resolvers/ai_asset_resolver.dart';
import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// The **one** place the protocol's image precedence is implemented.
///
/// ```text
/// url  →  network image (AppNetworkImage: CachedNetworkImage + shimmer)
/// assetId  →  bundled asset through AiAssetResolver
/// neither  →  the caller's own no-image state
/// ```
///
/// Every image-bearing node renders through this widget — the `image`
/// primitive, a `list_item`'s leading square, a `service_card` thumbnail, a
/// `provider_card` avatar, a `permission_request` illustration, a
/// `location_confirm` map. Duplicating the three-way decision per renderer is
/// how "URL wins" silently becomes "URL wins except in the avatar", so the
/// renderers pass a size and a fallback and nothing else.
///
/// Nothing here loads an image itself: remote media goes through
/// `AppNetworkImage`, which is the app's existing cached-network-image stack
/// with its shimmer placeholder and failure placeholder, and bundled assets go
/// through the same `Image.asset` / `AppSvgPicture` path they always used.
class AiUiImageView extends StatelessWidget {
  /// Creates a view of [source].
  const AiUiImageView({
    required this.source,
    required this.scope,
    required this.nodeType,
    required this.nodeId,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallback,
    super.key,
  });

  /// The canonical `{url?, assetId?}` object, already validated.
  final AiUiImageSource? source;

  /// Supplies the asset catalog and the diagnostics sink.
  final AiUiRenderScope scope;

  /// Named in a diagnostic when an asset cannot be resolved at render time.
  final String nodeType;
  final String nodeId;

  final double? width;
  final double? height;
  final BoxFit fit;

  /// Drawn when there is nothing to show: no source, an empty source, or an
  /// `assetId` the resolver does not know. Defaults to the design system's
  /// image placeholder, which is the right answer for a picture-shaped hole
  /// but not for an avatar — those pass their own.
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final image = source;

    // 1. A URL wins whenever it is usable. The validator has already checked
    //    the scheme, the userinfo and (if the host configured one) the
    //    allowlist, so this is never an arbitrary string.
    if (image != null && image.hasUrl) {
      return AppNetworkImage(
        image.url!,
        width: width,
        height: height,
        fit: fit,
        errorWidget: fallback,
      );
    }

    // 2. Then the bundled asset.
    if (image != null && image.hasAssetId) {
      final asset = scope.assets.resolve(image.assetId!);
      if (asset != null) return _asset(asset);

      // Published at validation time, missing now — a catalog that changed
      // under a cached payload. Report it rather than drawing a broken box.
      scope.diagnostics.report(
        AiUiDiagnostic(
          code: AiUiDiagnosticCode.unknownAssetId,
          path: nodeId,
          nodeType: nodeType,
          detail: 'asset unresolved at render time',
        ),
      );
    }

    // 3. The caller's no-image state.
    return fallback ??
        AppImagePlaceholder(width: width, height: height, fit: fit);
  }

  Widget _asset(AiUiAssetRef ref) => ref.isSvg
      ? AppSvgPicture.asset(ref.path, width: width, height: height, fit: fit)
      : Image.asset(
          ref.path,
          package: AppAssets.package,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, _, _) =>
              fallback ??
              AppImagePlaceholder(width: width, height: height, fit: fit),
        );
}
