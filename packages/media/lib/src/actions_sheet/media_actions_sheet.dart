import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// An action the user chose from the media action sheet.
enum MediaAction { view, gallery, files, camera, remove }

/// The Facebook-style action sheet opened from an edit affordance.
///
/// Generic: the title is supplied by the caller (no cover/avatar copy is
/// hardcoded), and View/Remove rows appear only when applicable.
class MediaActionsSheet extends StatelessWidget {
  const MediaActionsSheet({
    required this.hasMedia,
    this.allowRemove = true,
    super.key,
  });

  final bool hasMedia;
  final bool allowRemove;

  static Future<MediaAction?> show(
    BuildContext context, {
    required String title,
    required bool hasMedia,
    bool allowRemove = true,
  }) {
    return showAppBottomSheet<MediaAction>(
      context: context,
      title: title,
      child: MediaActionsSheet(hasMedia: hasMedia, allowRemove: allowRemove),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasMedia)
          _ActionRow(
            icon: Icons.visibility_outlined,
            label: 'media.view'.tr(),
            colors: colors,
            typography: typography,
            onTap: () => Navigator.of(context).pop(MediaAction.view),
          ),
        _ActionRow(
          icon: Icons.photo_library_outlined,
          label: 'media.choose_gallery'.tr(),
          colors: colors,
          typography: typography,
          onTap: () => Navigator.of(context).pop(MediaAction.gallery),
        ),
        _ActionRow(
          icon: Icons.folder_open_outlined,
          label: 'media.choose_files'.tr(),
          colors: colors,
          typography: typography,
          onTap: () => Navigator.of(context).pop(MediaAction.files),
        ),
        _ActionRow(
          icon: Icons.photo_camera_outlined,
          label: 'media.take_photo'.tr(),
          colors: colors,
          typography: typography,
          onTap: () => Navigator.of(context).pop(MediaAction.camera),
        ),
        if (allowRemove && hasMedia)
          _ActionRow(
            icon: Icons.delete_outline,
            label: 'media.remove'.tr(),
            colors: colors,
            typography: typography,
            destructive: true,
            onTap: () => Navigator.of(context).pop(MediaAction.remove),
          ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.colors,
    required this.typography,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final AppColors colors;
  final AppTypography typography;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? colors.error : colors.textPrimary;

    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Row(
              spacing: AppSpacing.md,
              children: [
                Icon(icon, size: 20, color: color),
                Text(
                  label,
                  style: typography.bodyMedium.copyWith(color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
