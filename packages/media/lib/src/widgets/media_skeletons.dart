import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Shimmer placeholder for a cover-photo slot while its image loads.
class MediaCoverSkeleton extends StatelessWidget {
  const MediaCoverSkeleton({this.height = 120, this.borderRadius, super.key});

  final double height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AppShimmer(
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: colors.onBackground,
          borderRadius: borderRadius ?? BorderRadius.circular(12),
        ),
      ),
    );
  }
}

/// Shimmer placeholder for a circular avatar slot while its image loads.
class MediaAvatarSkeleton extends StatelessWidget {
  const MediaAvatarSkeleton({this.size = 76, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AppShimmer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colors.onBackground,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
