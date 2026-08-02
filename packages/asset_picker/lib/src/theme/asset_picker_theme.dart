import 'package:app_assets/app_assets.dart';
import 'package:asset_picker/src/domain/enums/asset_source.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// User-facing copy for the source picker, grouped so an app can override it
/// wholesale (e.g. from a localisation layer) without touching layout.
@immutable
class AssetPickerTexts {
  const AssetPickerTexts({
    this.sheetTitle = 'Select action',
    this.cancel = 'Cancel',
    this.cameraLabel = 'Camera',
    this.cameraDescription = 'Take a new photo',
    this.galleryLabel = 'Upload from Gallery',
    this.galleryDescription = 'Choose from your library',
    this.filesLabel = 'Upload file',
    this.filesDescription = 'Browse documents and files',
    this.scannerLabel = 'Scan or capture',
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

/// Leading SVG icons for each source — Figma `2947:14236`.
@immutable
class AssetPickerIcons {
  const AssetPickerIcons({
    this.camera = AppSvgs.assetPickerScanCapture,
    this.gallery = AppSvgs.assetPickerGallery,
    this.files = AppSvgs.assetPickerUploadFile,
    this.scanner = AppSvgs.assetPickerScanCapture,
  });

  final String camera;
  final String gallery;
  final String files;
  final String scanner;

  String iconPathFor(AssetSource source) => switch (source) {
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
    required this.dragHandle,
    required this.divider,
    required this.rowDivider,
    required this.cancel,
    required this.destructive,
  });

  final Color surface;
  final Color title;
  final Color subtitle;
  final Color icon;
  final Color dragHandle;
  final Color divider;
  final Color rowDivider;
  final Color cancel;
  final Color destructive;
}

/// The single source of truth for how the asset-picker UI looks.
///
/// It mirrors the application's design system: call [AssetPickerTheme.of] to
/// build a theme whose colors, typography, spacing and radii come straight
/// from `context.appColors` / `context.appTypography` / `AppSpacing` /
/// `ActionSheetTokens`. Every field can be overridden without forking the
/// widgets.
@immutable
class AssetPickerTheme {
  const AssetPickerTheme({
    required this.colors,
    required this.texts,
    required this.icons,
    required this.titleStyle,
    required this.subtitleStyle,
    required this.tileTitleStyle,
    required this.cancelStyle,
    required this.sheetRadius,
    required this.horizontalPadding,
    required this.itemHeight,
    required this.cancelHeight,
    required this.leadingIconSize,
    required this.itemHorizontalGap,
    required this.dragHandleWidth,
    required this.dragHandleHeight,
    required this.dragHandleTopPadding,
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
    final brightness = Theme.of(context).brightness;
    final actionSpec = ActionSheetTokens.resolve(
      colors: appColors,
      typography: typography,
      brightness: brightness,
    );
    final bottomSpec = BottomSheetTokens.resolve(
      colors: appColors,
      typography: typography,
      brightness: brightness,
    );
    final isDark = brightness == Brightness.dark;

    return AssetPickerTheme(
      colors:
          colors ??
          AssetPickerColors(
            surface: actionSpec.surfaceColor,
            title: appColors.textPrimary,
            subtitle: appColors.textSecondary,
            icon: appColors.textPrimary,
            dragHandle: bottomSpec.dragHandleColor,
            divider: actionSpec.dividerColor,
            rowDivider: isDark ? appColors.gray700 : appColors.gray50,
            cancel: actionSpec.cancelStyle.color ?? appColors.textMuted,
            destructive: appColors.error,
          ),
      texts: texts ?? const AssetPickerTexts(),
      icons: icons ?? const AssetPickerIcons(),
      titleStyle: actionSpec.titleStyle,
      subtitleStyle: typography.smallNormal.copyWith(
        color: appColors.textSecondary,
      ),
      tileTitleStyle: actionSpec.itemStyle,
      cancelStyle: actionSpec.cancelStyle.copyWith(fontWeight: FontWeight.w500),
      sheetRadius: actionSpec.topRadius,
      horizontalPadding: actionSpec.horizontalPadding,
      itemHeight: actionSpec.itemHeight,
      cancelHeight: AppDimension.buttonMd,
      leadingIconSize: actionSpec.leadingIconSize,
      itemHorizontalGap: actionSpec.itemHorizontalGap,
      dragHandleWidth: bottomSpec.dragHandleWidth,
      dragHandleHeight: bottomSpec.dragHandleHeight,
      dragHandleTopPadding: bottomSpec.dragHandleTopPadding,
      showDragHandle: showDragHandle,
    );
  }

  /// Resolved color roles.
  final AssetPickerColors colors;

  /// User-facing copy.
  final AssetPickerTexts texts;

  /// Per-source leading icons.
  final AssetPickerIcons icons;

  /// Style for the sheet title.
  final TextStyle titleStyle;

  /// Style for the optional header subtitle.
  final TextStyle subtitleStyle;

  /// Style for a source row's primary label.
  final TextStyle tileTitleStyle;

  /// Style for the cancel action.
  final TextStyle cancelStyle;

  /// Corner radius of the bottom sheet.
  final BorderRadius sheetRadius;

  /// Horizontal inset for title, rows, and cancel.
  final double horizontalPadding;

  /// Height of each source row — Figma `56px`.
  final double itemHeight;

  /// Height of the cancel row — Figma `48px`.
  final double cancelHeight;

  /// Size of the leading glyph — Figma `24px`.
  final double leadingIconSize;

  /// Horizontal gap between a row's icon and its text.
  final double itemHorizontalGap;

  /// Drag-handle dimensions.
  final double dragHandleWidth;
  final double dragHandleHeight;
  final double dragHandleTopPadding;

  /// Whether to render the drag handle at the top of the sheet.
  final bool showDragHandle;
}
