import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:shared_ui/src/widgets/media_upload/media_upload_tile.dart';
import 'package:shared_ui/src/widgets/media_upload/media_upload_tile_data.dart';

/// Reusable multi-file upload grid: an "Add" tile, one [MediaUploadTile] per
/// item, a status summary header ("3 of 5 uploaded, 2 uploading, 1 failed"),
/// and an empty state when there are no items yet.
///
/// The overall state is always derived from [items] — this widget carries no
/// upload/business logic of its own.
class MediaUploadGrid extends StatelessWidget {
  const MediaUploadGrid({
    required this.items,
    super.key,
    this.maxFiles,
    this.crossAxisCount = 3,
    this.tileSize = 96,
    this.emptyStateLabel = 'No files added yet',
    this.addLabel = 'Add',
    this.onAdd,
    this.onPreview,
    this.onReplace,
    this.onRemove,
    this.onRetry,
    this.onRetryAll,
    this.emptyStateBuilder,
  });

  final List<MediaUploadTileData> items;

  /// `null` means unbounded — the Add tile is always shown.
  final int? maxFiles;

  final int crossAxisCount;
  final double tileSize;
  final String emptyStateLabel;
  final String addLabel;

  /// Overrides the built-in empty state (icon + label + Add button) when
  /// [items] is empty — e.g. to match a feature-specific "drop zone" look.
  /// The builder is responsible for calling [onAdd] itself.
  final Widget Function(BuildContext context)? emptyStateBuilder;

  final VoidCallback? onAdd;
  final void Function(String id)? onPreview;
  final void Function(String id)? onReplace;
  final void Function(String id)? onRemove;
  final void Function(String id)? onRetry;
  final VoidCallback? onRetryAll;

  int get _uploadedCount =>
      items.where((i) => i.status == MediaUploadTileStatus.success).length;

  int get _uploadingCount =>
      items.where((i) => i.status == MediaUploadTileStatus.uploading).length;

  int get _failedCount =>
      items.where((i) => i.status == MediaUploadTileStatus.failure).length;

  bool get _canAddMore => maxFiles == null || items.length < maxFiles!;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return emptyStateBuilder?.call(context) ??
          _EmptyState(
            label: emptyStateLabel,
            addLabel: addLabel,
            onAdd: onAdd,
          );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SummaryHeader(
          uploadedCount: _uploadedCount,
          totalCount: items.length,
          uploadingCount: _uploadingCount,
          failedCount: _failedCount,
          onRetryAll: _failedCount > 0 ? onRetryAll : null,
        ),
        SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final item in items)
              MediaUploadTile(
                key: ValueKey(item.id),
                data: item,
                size: tileSize,
                onPreview: onPreview == null ? null : () => onPreview!(item.id),
                onReplace: onReplace == null ? null : () => onReplace!(item.id),
                onRemove: onRemove == null ? null : () => onRemove!(item.id),
                onRetry: onRetry == null ? null : () => onRetry!(item.id),
              ),
            if (_canAddMore) _AddTile(size: tileSize, onTap: onAdd),
          ],
        ),
      ],
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({
    required this.uploadedCount,
    required this.totalCount,
    required this.uploadingCount,
    required this.failedCount,
    this.onRetryAll,
  });

  final int uploadedCount;
  final int totalCount;
  final int uploadingCount;
  final int failedCount;
  final VoidCallback? onRetryAll;

  @override
  Widget build(BuildContext context) {
    final typography = context.appTypography;
    final colors = context.appColors;

    final parts = <String>['$uploadedCount of $totalCount uploaded'];
    if (uploadingCount > 0) parts.add('$uploadingCount uploading');
    if (failedCount > 0) parts.add('$failedCount failed');

    return Row(
      children: [
        Expanded(
          child: Text(
            parts.join(' · '),
            style: typography.smallNormal.copyWith(color: colors.textMuted),
          ),
        ),
        if (onRetryAll != null)
          TextButton(
            onPressed: onRetryAll,
            child: const Text('Retry all'),
          ),
      ],
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.size, this.onTap});

  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimension.radiusMd),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          border: Border.all(color: colors.border),
          borderRadius: BorderRadius.circular(AppDimension.radiusMd),
        ),
        child: Icon(Icons.add, color: colors.textSecondary),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.label, required this.addLabel, this.onAdd});

  final String label;
  final String addLabel;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(AppDimension.radiusMd),
      ),
      child: Column(
        children: [
          Icon(Icons.image_outlined, color: colors.textSecondary, size: 32),
          SizedBox(height: AppSpacing.sm),
          Text(
            label,
            style: typography.smallNormal.copyWith(color: colors.textMuted),
          ),
          SizedBox(height: AppSpacing.md),
          AppButtonPresets.primary(label: addLabel, onPressed: onAdd),
        ],
      ),
    );
  }
}
