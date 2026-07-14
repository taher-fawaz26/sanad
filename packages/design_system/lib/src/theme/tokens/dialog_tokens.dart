import 'package:design_system/design_system.dart' show AppDialog, AppTheme;
import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';

/// Visual image placement for [AppDialog] — Figma `Popovers` (`40:10031`).
enum AppDialogImageLayout {
  /// Text-only popover (`40:10031`, `40:10071`, `40:10050`, `40:10079`).
  none,

  /// Centered 120×120 image (`40:10040`, `40:10092`).
  imageLarge,

  /// Centered 64×64 image (`40:10060`, `40:10085`), or featured icon ring
  /// (`194:5419`) when [AppPopover.featureIconColor] is set.
  iconSmall,

  /// Full-width hero header (`40:10120`, `40:10112`).
  heroHeader,
}

/// Resolved styling for [AppDialog].
@immutable
class DialogStyleSpec {
  const DialogStyleSpec({
    required this.borderRadius,
    required this.backgroundColor,
    required this.barrierColor,
    required this.contentPadding,
    required this.contentPaddingWithImage,
    required this.sectionGap,
    required this.textGap,
    required this.actionGap,
    required this.titleStyle,
    required this.descriptionStyle,
    required this.imageLargeSize,
    required this.imageSmallSize,
    required this.featureIconOuterSize,
    required this.imageBorderRadius,
    required this.heroImageHeight,
    required this.imagePlaceholderColor,
    required this.horizontalInset,
  });

  final BorderRadius borderRadius;
  final Color backgroundColor;
  final Color barrierColor;
  final EdgeInsets contentPadding;
  final EdgeInsets contentPaddingWithImage;
  final double sectionGap;
  final double textGap;
  final double actionGap;
  final TextStyle titleStyle;
  final TextStyle descriptionStyle;
  final double imageLargeSize;
  final double imageSmallSize;
  final double featureIconOuterSize;
  final BorderRadius imageBorderRadius;
  final double heroImageHeight;
  final Color imagePlaceholderColor;
  final double horizontalInset;

  EdgeInsets paddingFor(AppDialogImageLayout layout) {
    return switch (layout) {
      AppDialogImageLayout.imageLarge ||
      AppDialogImageLayout.iconSmall =>
        contentPaddingWithImage,
      AppDialogImageLayout.none || AppDialogImageLayout.heroHeader =>
        contentPadding,
    };
  }

  double inlineImageSize(AppDialogImageLayout layout) {
    return switch (layout) {
      AppDialogImageLayout.imageLarge => imageLargeSize,
      AppDialogImageLayout.iconSmall => imageSmallSize,
      AppDialogImageLayout.none || AppDialogImageLayout.heroHeader => 0,
    };
  }
}

/// Theme extension registered in [AppTheme] for Figma popovers.
@immutable
class AppDialogTheme extends ThemeExtension<AppDialogTheme> {
  const AppDialogTheme({required this.spec});

  /// Figma `Popovers` (`40:10031`) spec for the active brightness.
  final DialogStyleSpec spec;

  @override
  AppDialogTheme copyWith({DialogStyleSpec? spec}) {
    return AppDialogTheme(spec: spec ?? this.spec);
  }

  @override
  AppDialogTheme lerp(covariant AppDialogTheme? other, double t) {
    if (other == null) {
      return this;
    }
    return t < 0.5 ? this : other;
  }
}

extension AppDialogThemeX on BuildContext {
  AppDialogTheme get appDialogTheme =>
      Theme.of(this).extension<AppDialogTheme>()!;
}

/// Figma `Popovers` token resolver.
abstract final class DialogTokens {
  DialogTokens._();

  static const double borderRadius = 16;
  static const double contentPaddingValue = 24;
  static const double contentPaddingTopWithImage = 32;
  static const double sectionGap = 24;
  static const double textGap = 8;
  static const double actionGap = 12;
  static const double titleSize = 24;
  static const double titleLineHeight = 32;
  static const double bodySize = 16;
  static const double bodyLineHeight = 24;
  static const double imageLargeSize = 120;
  static const double imageSmallSize = 64;
  /// Figma success popover ring (`194:5419`) — 100 dp outer circle.
  static const double featureIconOuterSize = 100;
  static const double imageBorderRadius = 16;
  static const double heroImageHeight = 186;
  static const double horizontalInset = 24;
  static const double barrierOpacity = 0.7;

  static AppDialogTheme themeExtension({
    required AppColors colors,
    required AppTypography typography,
    required Brightness brightness,
  }) {
    return AppDialogTheme(
      spec: resolve(
        colors: colors,
        typography: typography,
        brightness: brightness,
      ),
    );
  }

  static DialogStyleSpec resolve({
    required AppColors colors,
    required AppTypography typography,
    required Brightness brightness,
  }) {
    final isDark = brightness == Brightness.dark;
    final radius = responsiveDimension(borderRadius);
    final imageRadius = responsiveDimension(imageBorderRadius);
    final padding = responsiveDimension(contentPaddingValue);
    final paddingTop = responsiveDimension(contentPaddingTopWithImage);

    return DialogStyleSpec(
      borderRadius: BorderRadius.circular(radius),
      backgroundColor: isDark ? colors.palettes.dark.shade900 : colors.surface,
      barrierColor: colors.palettes.dark.shade950.withValues(
        alpha: barrierOpacity,
      ),
      contentPadding: EdgeInsets.all(padding),
      contentPaddingWithImage: EdgeInsets.fromLTRB(
        padding,
        paddingTop,
        padding,
        padding,
      ),
      sectionGap: responsiveDimension(sectionGap),
      textGap: responsiveDimension(textGap),
      actionGap: responsiveDimension(actionGap),
      titleStyle: typography.title3.copyWith(
        fontWeight: FontWeight.w700,
        color: colors.textPrimary,
      ),
      descriptionStyle: typography.regularNormal.copyWith(
        color: isDark ? colors.palettes.dark.shade400 : colors.textMuted,
      ),
      imageLargeSize: responsiveDimension(imageLargeSize),
      imageSmallSize: responsiveDimension(imageSmallSize),
      featureIconOuterSize: responsiveDimension(featureIconOuterSize),
      imageBorderRadius: BorderRadius.circular(imageRadius),
      heroImageHeight: responsiveDimension(heroImageHeight),
      imagePlaceholderColor: isDark ? colors.gray800 : colors.gray200,
      horizontalInset: responsiveDimension(horizontalInset),
    );
  }
}
