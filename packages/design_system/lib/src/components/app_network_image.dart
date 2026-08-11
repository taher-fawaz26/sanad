import 'package:cached_network_image/cached_network_image.dart';
import 'package:design_system/src/components/app_image_placeholder.dart';
import 'package:design_system/src/components/app_shimmer.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:flutter/material.dart';

/// A network image backed by [CachedNetworkImage].
///
/// Shows an [AppShimmer] skeleton while the image loads and [AppImagePlaceholder]
/// when the URL is empty or the request fails. Use this instead of raw
/// [Image.network] across all feature packages so caching, shimmer, and error
/// states are consistent.
///
/// Pass [borderRadius] to clip the result without an extra [ClipRRect] at
/// the call site.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.errorWidget,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  /// Widget shown when the image fails to load. Defaults to [AppImagePlaceholder]
  /// sized to [width] × [height].
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    if (url.isEmpty) {
      return AppImagePlaceholder(
        width: width,
        height: height,
        fit: fit,
        borderRadius: borderRadius,
      );
    }

    Widget image = CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: (_, __) => AppShimmer(
        child: Container(
          width: width,
          height: height,
          color: colors.onBackground,
        ),
      ),
      errorWidget: (_, __, ___) =>
          errorWidget ??
          AppImagePlaceholder(
            fit: fit,
          ),
    );

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }
}
