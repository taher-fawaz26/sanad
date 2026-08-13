import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:services/src/domain/entities/provider_service_image_entity.dart';

const _imageGridColumns = 3;

/// Read-only preview of a service's uploaded images — Figma `4715:26510`
/// (label + an equal-width row of every image, `80px` tall, `6px` radius).
///
/// Display-only: adding, deleting, or setting the main image happens
/// through the Edit Service flow, not from Service Details.
class ServiceImagesPreview extends StatelessWidget {
  const ServiceImagesPreview({required this.images, super.key});

  final List<ProviderServiceImageEntity> images;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final radius = BorderRadius.circular(AppDimension.radiusSm);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'services.details.images'.tr(),
          style: typography
              .medium(typography.smallNormal)
              .copyWith(color: colors.textSecondary),
        ),
        SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final gap = AppSpacing.md;
            final tileWidth =
                (constraints.maxWidth - gap * (_imageGridColumns - 1)) /
                _imageGridColumns;

            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final image in images)
                  SizedBox(
                    key: ValueKey(image.id),
                    width: tileWidth,
                    height: responsiveDimension(80),
                    child: AppNetworkImage(image.url, borderRadius: radius),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
