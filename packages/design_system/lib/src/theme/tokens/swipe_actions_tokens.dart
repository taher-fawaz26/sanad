import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:flutter/material.dart';

/// Semantic intent for an `AppSwipeAction` — mirrors `AppButtonIntent`'s
/// destructive/warning conventions instead of forcing arbitrary colors.
enum AppSwipeActionVariant {
  /// Low-emphasis action, e.g. "View".
  neutral,

  /// Main-brand emphasis, e.g. "Edit" / "Unsuspend".
  primary,

  /// Caution emphasis, e.g. "Suspend" / "Cancel".
  warning,

  /// Destructive emphasis, e.g. "Delete".
  destructive,
}

/// Resolved colours for one `AppSwipeAction` render pass.
@immutable
class SwipeActionSurfaceColors {
  const SwipeActionSurfaceColors({
    required this.background,
    required this.foreground,
  });

  final Color background;
  final Color foreground;
}

/// AppSwipeActions token resolver — spacing, radius, and per-variant
/// colours pulled from existing design tokens (no new palette entries).
abstract final class SwipeActionsTokens {
  SwipeActionsTokens._();

  static double actionWidth() => responsiveDimension(76);

  /// Gap around each action button — splits into the pane's outer inset and
  /// the space between adjacent buttons, so each renders as a separate
  /// floating pill rather than a contiguous strip.
  static double actionSpacing() => responsiveDimension(6);

  static double iconSize() => AppDimension.iconMenu;

  static BorderRadius borderRadius() =>
      BorderRadius.circular(AppDimension.radiusMd);

  static SwipeActionSurfaceColors resolve({
    required AppSwipeActionVariant variant,
    required AppColors colors,
    required bool enabled,
  }) {
    if (!enabled) {
      return SwipeActionSurfaceColors(
        background: colors.disabled,
        foreground: colors.onDisabled,
      );
    }

    return switch (variant) {
      AppSwipeActionVariant.neutral => SwipeActionSurfaceColors(
        background: colors.gray100,
        foreground: colors.textPrimary,
      ),
      AppSwipeActionVariant.primary => SwipeActionSurfaceColors(
        background: colors.primary,
        foreground: colors.onPrimary,
      ),
      AppSwipeActionVariant.warning => SwipeActionSurfaceColors(
        background: colors.warning,
        foreground: colors.onWarning,
      ),
      AppSwipeActionVariant.destructive => SwipeActionSurfaceColors(
        background: colors.error,
        foreground: colors.onError,
      ),
    };
  }
}
