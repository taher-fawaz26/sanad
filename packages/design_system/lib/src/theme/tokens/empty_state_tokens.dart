import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/spacing/responsive_spacing.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';

/// Resolved styling for [AppEmptyState].
@immutable
class EmptyStateStyleSpec {
  const EmptyStateStyleSpec({
    required this.horizontalPadding,
    required this.topPadding,
    required this.bottomPadding,
    required this.sectionGap,
    required this.textGap,
    required this.contentWidth,
    required this.titleStyle,
    required this.descriptionStyle,
  });

  final double horizontalPadding;
  final double topPadding;
  final double bottomPadding;
  final double sectionGap;
  final double textGap;
  final double contentWidth;
  final TextStyle titleStyle;
  final TextStyle descriptionStyle;
}

/// Figma `empty states` (`321:8333`).
abstract final class EmptyStateTokens {
  EmptyStateTokens._();

  static const double horizontalPadding = 24;
  static const double topPadding = 16;
  static const double bottomPadding = 12;
  static const double sectionGap = 12;
  static const double textGap = 8;
  static const double contentWidth = 279;

  // Illustration sizes confirmed from Figma sub-frames.
  static const double networkIllustrationSize = 218.33;
  static const double emptyIllustrationWidth = 218.33;
  static const double emptyIllustrationHeight = 126.26;
  static const double searchIllustrationWidth = 193.98;
  static const double searchIllustrationHeight = 157.61;
  static const double workerIllustrationWidth = 129.35;
  static const double workerIllustrationHeight = 157.47;

  static EmptyStateStyleSpec resolve({
    required AppColors colors,
    required AppTypography typography,
  }) {
    return EmptyStateStyleSpec(
      horizontalPadding: responsiveDimension(horizontalPadding),
      topPadding: responsiveDimension(topPadding),
      bottomPadding: responsiveDimension(bottomPadding),
      sectionGap: AppSpacing.xxl,
      textGap: AppSpacing.sm,
      contentWidth: responsiveDimension(contentWidth),
      titleStyle: typography.title3.copyWith(
        fontWeight: FontWeight.w700,
        color: colors.textPrimary,
      ),
      descriptionStyle: typography.regularNormal.copyWith(
        color: colors.textSecondary,
      ),
    );
  }
}
