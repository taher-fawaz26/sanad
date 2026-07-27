import 'package:asset_picker/src/domain/enums/asset_source.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// User-facing copy for the source picker, grouped so an app can override it
/// wholesale (e.g. from a localisation layer) without touching layout.
@immutable
class AssetPickerTexts {
  const AssetPickerTexts({
    this.sheetTitle = 'Add attachment',
    this.cancel = 'Cancel',
    this.cameraLabel = 'Camera',
    this.cameraDescription = 'Take a new photo',
    this.galleryLabel = 'Gallery',
    this.galleryDescription = 'Choose from your library',
    this.filesLabel = 'Files',
    this.filesDescription = 'Browse documents and files',
    this.scannerLabel = 'Scan document',
    this.scannerDescription = 'Scan a physical document',
  });

  final String sheetTitle;
  final String cancel;
  final String cameraLabel;
  final String cameraDescription;
  final String galleryLabel;
  final String galleryDescription;
  final String filesLabel;
  final String filesDescription;
  final String scannerLabel;
  final String scannerDescription;

  /// The row label for [source].
  String labelFor(AssetSource source) => switch (source) {
    AssetSource.camera => cameraLabel,
    AssetSource.gallery => galleryLabel,
    AssetSource.files => filesLabel,
    AssetSource.scanner => scannerLabel,
  };

  /// The row description for [source].
  String descriptionFor(AssetSource source) => switch (source) {
    AssetSource.camera => cameraDescription,
    AssetSource.gallery => galleryDescription,
    AssetSource.files => filesDescription,
    AssetSource.scanner => scannerDescription,
  };
}

/// Leading icons for each source. Swap individual icons or the whole set.
@immutable
class AssetPickerIcons {
  const AssetPickerIcons({
    this.camera = Icons.photo_camera_outlined,
    this.gallery = Icons.photo_library_outlined,
    this.files = Icons.folder_open_outlined,
    this.scanner = Icons.document_scanner_outlined,
  });

  final IconData camera;
  final IconData gallery;
  final IconData files;
  final IconData scanner;

  IconData iconFor(AssetSource source) => switch (source) {
    AssetSource.camera => camera,
    AssetSource.gallery => gallery,
    AssetSource.files => files,
    AssetSource.scanner => scanner,
  };
}

/// The resolved color roles the picker UI paints with. Defaults are pulled
/// from the design system via [AssetPickerTheme.of].
@immutable
class AssetPickerColors {
  const AssetPickerColors({
    required this.surface,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBackground,
    required this.dragHandle,
    required this.divider,
    required this.destructive,
  });

  final Color surface;
  final Color title;
  final Color subtitle;
  final Color icon;
  final Color iconBackground;
  final Color dragHandle;
  final Color divider;
  final Color destructive;
}

/// The single source of truth for how the asset-picker UI looks.
///
/// It mirrors the application's design system: call [AssetPickerTheme.of] to
/// build a theme whose colors, typography, spacing and radii come straight
/// from `context.appColors` / `context.appTypography` / `AppSpacing` /
/// `AppRadius`. Every field can be overridden without forking the widgets.
@immutable
class AssetPickerTheme {
  const AssetPickerTheme({
    required this.colors,
    required this.texts,
    required this.icons,
    required this.titleStyle,
    required this.subtitleStyle,
    required this.tileTitleStyle,
    required this.tileSubtitleStyle,
    required this.sheetRadius,
    required this.tileRadius,
    required this.contentPadding,
    required this.tilePadding,
    required this.tileGap,
    required this.iconSize,
    required this.iconContainerSize,
    required this.dragHandleWidth,
    required this.dragHandleHeight,
    this.showDragHandle = true,
  });

  /// Builds the default theme from the ambient design-system tokens.
  ///
  /// Pass any of the group overrides ([colors], [texts], [icons]) to customise
  /// without losing the design-system-derived defaults for everything else.
  factory AssetPickerTheme.of(
    BuildContext context, {
    AssetPickerColors? colors,
    AssetPickerTexts? texts,
    AssetPickerIcons? icons,
    bool showDragHandle = true,
  }) {
    final appColors = context.appColors;
    final typography = context.appTypography;

    return AssetPickerTheme(
      colors:
          colors ??
          AssetPickerColors(
            surface: appColors.surface,
            title: appColors.textPrimary,
            subtitle: appColors.textSecondary,
            icon: appColors.primary,
            iconBackground: appColors.selectedContainer,
            dragHandle: appColors.divider,
            divider: appColors.divider,
            destructive: appColors.error,
          ),
      texts: texts ?? const AssetPickerTexts(),
      icons: icons ?? const AssetPickerIcons(),
      titleStyle: typography.title3.copyWith(color: appColors.textPrimary),
      subtitleStyle: typography.smallNormal.copyWith(
        color: appColors.textSecondary,
      ),
      tileTitleStyle: typography.largeNormal.copyWith(
        color: appColors.textPrimary,
        fontWeight: FontWeight.w500,
      ),
      tileSubtitleStyle: typography.smallNormal.copyWith(
        color: appColors.textSecondary,
      ),
      sheetRadius: AppRadius.circularLg,
      tileRadius: AppRadius.circularMd,
      contentPadding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      tilePadding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      tileGap: AppSpacing.md,
      iconSize: 24,
      iconContainerSize: 44,
      dragHandleWidth: 40,
      dragHandleHeight: 4,
      showDragHandle: showDragHandle,
    );
  }

  /// Resolved color roles.
  final AssetPickerColors colors;

  /// User-facing copy.
  final AssetPickerTexts texts;

  /// Per-source leading icons.
  final AssetPickerIcons icons;

  /// Style for the optional header title above the picker.
  final TextStyle titleStyle;

  /// Style for the optional header subtitle.
  final TextStyle subtitleStyle;

  /// Style for a source row's primary label.
  final TextStyle tileTitleStyle;

  /// Style for a source row's supporting description.
  final TextStyle tileSubtitleStyle;

  /// Corner radius of the bottom sheet.
  final BorderRadius sheetRadius;

  /// Corner radius of the leading icon container in a row.
  final BorderRadius tileRadius;

  /// Padding around the sheet content.
  final EdgeInsets contentPadding;

  /// Padding inside each source row.
  final EdgeInsets tilePadding;

  /// Horizontal gap between a row's icon and its text.
  final double tileGap;

  /// Size of the leading glyph.
  final double iconSize;

  /// Size of the rounded container behind the leading glyph.
  final double iconContainerSize;

  /// Drag-handle dimensions.
  final double dragHandleWidth;
  final double dragHandleHeight;

  /// Whether to render the drag handle at the top of the sheet.
  final bool showDragHandle;
}
