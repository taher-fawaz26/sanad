import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// The single place protocol vocabulary becomes SANAD design tokens.
///
/// Every mapping is one-way and total. The protocol has no way to name a
/// colour, a pixel value or a font, so this file is the only thing that
/// decides how `tone: "success"` or `gap: "lg"` actually looks — which means
/// the design system can evolve without touching the protocol or the agent.
abstract final class AiUiTokens {
  static TextStyle textStyle(
    BuildContext context,
    AiUiTextStyleToken style,
    AiUiEmphasis emphasis,
  ) {
    final typography = context.appTypography;
    final base = switch (style) {
      AiUiTextStyleToken.title => typography.title3,
      AiUiTextStyleToken.body => typography.regularNormal,
      AiUiTextStyleToken.caption => typography.smallNormal,
      AiUiTextStyleToken.label => typography.tinyNormal,
    };

    final weighted = switch (emphasis) {
      AiUiEmphasis.strong => typography.semiBold(base),
      AiUiEmphasis.normal || AiUiEmphasis.muted => base,
    };

    return weighted.copyWith(color: emphasisColor(context, emphasis));
  }

  static Color emphasisColor(BuildContext context, AiUiEmphasis emphasis) {
    final colors = context.appColors;
    return switch (emphasis) {
      AiUiEmphasis.normal || AiUiEmphasis.strong => colors.textPrimary,
      AiUiEmphasis.muted => colors.textMuted,
    };
  }

  static Color toneColor(BuildContext context, AiUiTone tone) {
    final colors = context.appColors;
    return switch (tone) {
      AiUiTone.neutral => colors.textPrimary,
      AiUiTone.primary => colors.primary,
      AiUiTone.info => colors.info,
      AiUiTone.success => colors.success,
      AiUiTone.warning => colors.warning,
      AiUiTone.error => colors.error,
    };
  }

  static double spacing(AiUiSpacingStep step) => switch (step) {
    AiUiSpacingStep.xs => AppSpacing.xs,
    AiUiSpacingStep.sm => AppSpacing.sm,
    AiUiSpacingStep.md => AppSpacing.md,
    AiUiSpacingStep.lg => AppSpacing.lg,
    AiUiSpacingStep.xl => AppSpacing.xl,
  };

  static double iconSize(AiUiIconSize size) => switch (size) {
    AiUiIconSize.sm => AppDimension.iconCompact,
    AiUiIconSize.md => AppDimension.iconMd,
    AiUiIconSize.lg => AppDimension.iconMenu,
  };

  /// Directional by construction: `start`/`end` resolve against the ambient
  /// text direction, so a row flips correctly under Arabic without the agent
  /// knowing anything about RTL.
  static TextAlign textAlign(AiUiMainAxisAlign align) => switch (align) {
    AiUiMainAxisAlign.start ||
    AiUiMainAxisAlign.spaceBetween => TextAlign.start,
    AiUiMainAxisAlign.center => TextAlign.center,
    AiUiMainAxisAlign.end => TextAlign.end,
  };

  static MainAxisAlignment mainAxis(AiUiMainAxisAlign align) => switch (align) {
    AiUiMainAxisAlign.start => MainAxisAlignment.start,
    AiUiMainAxisAlign.center => MainAxisAlignment.center,
    AiUiMainAxisAlign.end => MainAxisAlignment.end,
    AiUiMainAxisAlign.spaceBetween => MainAxisAlignment.spaceBetween,
  };

  static WrapAlignment wrapAlignment(AiUiMainAxisAlign align) =>
      switch (align) {
        AiUiMainAxisAlign.start => WrapAlignment.start,
        AiUiMainAxisAlign.center => WrapAlignment.center,
        AiUiMainAxisAlign.end => WrapAlignment.end,
        AiUiMainAxisAlign.spaceBetween => WrapAlignment.spaceBetween,
      };

  static CrossAxisAlignment crossAxis(AiUiCrossAxisAlign align) =>
      switch (align) {
        AiUiCrossAxisAlign.start => CrossAxisAlignment.start,
        AiUiCrossAxisAlign.center => CrossAxisAlignment.center,
        AiUiCrossAxisAlign.end => CrossAxisAlignment.end,
      };

  static AppButtonVariant buttonVariant(AiUiButtonVariant variant) =>
      switch (variant) {
        AiUiButtonVariant.primary => AppButtonVariant.primary,
        AiUiButtonVariant.secondary => AppButtonVariant.secondary,
        AiUiButtonVariant.outline => AppButtonVariant.outline,
        AiUiButtonVariant.transparent => AppButtonVariant.transparent,
      };

  static AppButtonIntent buttonIntent(AiUiButtonIntent intent) =>
      switch (intent) {
        AiUiButtonIntent.standard => AppButtonIntent.standard,
        AiUiButtonIntent.warning => AppButtonIntent.warning,
        AiUiButtonIntent.destructive => AppButtonIntent.destructive,
        AiUiButtonIntent.neutral => AppButtonIntent.neutral,
      };

  static AppButtonSize buttonSize(AiUiButtonSize size) => switch (size) {
    AiUiButtonSize.block => AppButtonSize.block,
    AiUiButtonSize.large => AppButtonSize.large,
    AiUiButtonSize.small => AppButtonSize.small,
  };

  /// The design system's chip tones are a deliberately smaller set than the
  /// protocol's, so several protocol tones collapse onto `normal`. Widening
  /// `AppChipTone` later needs no protocol change.
  static AppChipTone chipTone(AiUiTone tone) => switch (tone) {
    AiUiTone.success => AppChipTone.softSuccess,
    AiUiTone.neutral => AppChipTone.softNeutral,
    AiUiTone.primary ||
    AiUiTone.info ||
    AiUiTone.warning ||
    AiUiTone.error => AppChipTone.normal,
  };

  static AppStatusBadgeType badgeType(AiUiTone tone) => switch (tone) {
    AiUiTone.success => AppStatusBadgeType.success,
    AiUiTone.error => AppStatusBadgeType.alert,
    AiUiTone.warning => AppStatusBadgeType.warning,
    AiUiTone.info ||
    AiUiTone.neutral ||
    AiUiTone.primary => AppStatusBadgeType.info,
  };

  static BoxFit boxFit(AiUiImageFit fit) => switch (fit) {
    AiUiImageFit.cover => BoxFit.cover,
    AiUiImageFit.contain => BoxFit.contain,
  };

  /// `null` means "no intrinsic ratio — size me from a fixed thumb box".
  static double? aspectRatio(AiUiImageAspect aspect) => switch (aspect) {
    AiUiImageAspect.square => 1,
    AiUiImageAspect.wide => 16 / 9,
    AiUiImageAspect.thumb => null,
  };

  static const double thumbSize = 56;

  /// Const because it sits inside `const AppLoadingIndicator(...)`, which
  /// rules out `AppDimension`'s responsive getters.
  static const double loadingGlyphSize = 24;
}
