import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:services/src/presentation/models/service_image_tile.dart';
import 'package:services/src/presentation/widgets/service_image_card.dart';
import 'package:shared_ui/shared_ui.dart';

/// The single canonical image-editor UI shared by Add Service and Edit
/// Service (Figma `5261:44387`/`5222:44137`) — header (label + required
/// asterisk + max-count badge), empty-state drop zone, and the
/// [ServiceImageCard]/[ServiceImageAddCard] grid.
///
/// Purely presentational: knows nothing about `MediaUploadBloc`,
/// `ServiceImagesBloc`, use cases, or any backend endpoint. Callers own
/// [items] (in display order — never sorted here, so "Main" changes can
/// never reorder the grid) and decide what each callback means; this
/// widget only reports which tile id was interacted with.
class ServiceImagesEditor extends StatelessWidget {
  const ServiceImagesEditor({
    required this.items,
    required this.maxImages,
    required this.label,
    required this.onMenuTap,
    required this.onRetry,
    required this.onAddTap,
    super.key,
    this.isRequired = false,
  });

  /// Every rendered tile, in caller-owned display order.
  final List<ServiceImageTile> items;

  /// Canonical image-count ceiling — always [kMaxServiceImages], injected
  /// rather than hardcoded here so there is exactly one declaration.
  final int maxImages;

  /// Field label shown while [items] is empty (e.g. "Add images").
  final String label;

  /// Whether the empty-state label shows the required asterisk. Add Service
  /// requires at least one image; Edit Service does not (images are
  /// optional to change).
  final bool isRequired;

  /// "⋮" tapped for the tile with this id. What happens (confirm-and-remove
  /// for a staged image, an action sheet with Set Main/Delete for a
  /// committed one) is entirely the caller's decision.
  final ValueChanged<String> onMenuTap;

  /// "Retry" tapped for a failed tile.
  final ValueChanged<String> onRetry;

  /// The drop zone or the trailing add-card was tapped.
  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    final isEmpty = items.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: AppFieldLabel(
                label: isEmpty
                    ? label
                    : 'services.images_count_label'.tr(
                        namedArgs: {
                          'count': items.length.toString(),
                          'max': maxImages.toString(),
                        },
                      ),
                isRequired: isRequired && isEmpty,
              ),
            ),
            Flexible(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.appColors.palettes.sky.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Text(
                    'services.images_max_badge'.tr(
                      namedArgs: {'max': maxImages.toString()},
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.appTypography.tinyNormal.copyWith(
                      color: context.appColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.md),
        if (isEmpty) _ImagesDropZone(onTap: onAddTap) else _buildGrid(),
      ],
    );
  }

  Widget _buildGrid() {
    final canAddMore = items.length < maxImages;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final item in items)
          ServiceImageCard(
            key: ValueKey(item.data.id),
            data: item.data,
            isMain: item.isMain,
            isBusy: item.isBusy,
            onMenuTap: () => onMenuTap(item.data.id),
            onRetry: item.data.status == MediaUploadTileStatus.failure
                ? () => onRetry(item.data.id)
                : null,
          ),
        if (canAddMore) ServiceImageAddCard(onTap: onAddTap),
      ],
    );
  }
}

class _ImagesDropZone extends StatelessWidget {
  const _ImagesDropZone({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimension.radiusMd),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.xxl,
        ),
        decoration: BoxDecoration(
          color: colors.palettes.sky.shade50,
          borderRadius: BorderRadius.circular(AppDimension.radiusMd),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 24, color: colors.primary),
            SizedBox(height: AppSpacing.sm),
            Text(
              'services.add_service.images_add_label'.tr(),
              style: typography.regularNormal.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              'services.add_service.images_max_size_caption'.tr(),
              textAlign: TextAlign.center,
              style: typography.smallNormal.copyWith(color: colors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
