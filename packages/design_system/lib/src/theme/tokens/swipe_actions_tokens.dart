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

/// How an `AppSwipeActions` pane composes its actions.
///
/// The two styles are whole visual specs, not a single knob: they differ in
/// cell width, corner treatment, neutral colours, glyph size and whether a
/// caption is drawn. Mixing values between them produces neither design.
enum AppSwipeActionsStyle {
  /// Each action is its own floating pill, inset from the row edge and
  /// separated from its neighbour — the provider app's list rows (Branches,
  /// Services, Workers, Invitations).
  separated,

  /// One contiguous strip: the cells butt together with no gap and no inset,
  /// and the group as a whole is clipped to the row's shape — Figma
  /// `actions` (`8487:31503`), used by the client's Conversation History.
  ///
  /// The grouped pane is what a platform swipe row looks like on both iOS and
  /// Android; [separated] predates it and is kept because changing four
  /// shipped provider screens is not this style's job.
  grouped,
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

  /// Width of one action cell.
  ///
  /// [AppSwipeActionsStyle.separated] keeps the 76dp pill the provider rows
  /// ship today; [AppSwipeActionsStyle.grouped] uses Figma's 64dp cell
  /// (`8487:31458`), which is narrower precisely because it no longer has to
  /// carry its own margins.
  static double actionWidth([
    AppSwipeActionsStyle style = AppSwipeActionsStyle.separated,
  ]) => switch (style) {
    AppSwipeActionsStyle.separated => responsiveDimension(76),
    AppSwipeActionsStyle.grouped => responsiveDimension(64),
  };

  /// Gap around each action button in [AppSwipeActionsStyle.separated] —
  /// splits into the pane's outer inset and the space between adjacent
  /// buttons, so each renders as a separate floating pill.
  ///
  /// [AppSwipeActionsStyle.grouped] has no equivalent: its cells are flush by
  /// definition, and any value here would be the gap the design exists to
  /// remove.
  static double actionSpacing() => responsiveDimension(6);

  /// Glyph size inside an action.
  ///
  /// Grouped uses Figma's 19dp icon (`8487:31452`) over its 12dp caption;
  /// separated keeps the shared menu-icon size it was built against.
  static double iconSize([
    AppSwipeActionsStyle style = AppSwipeActionsStyle.separated,
  ]) => switch (style) {
    AppSwipeActionsStyle.separated => AppDimension.iconMenu,
    AppSwipeActionsStyle.grouped => responsiveDimension(19),
  };

  /// Gap between an action's glyph and its caption — Figma `gap-[3px]`.
  static double contentGap() => responsiveDimension(3);

  /// Caption size for a grouped action — Figma 12dp on an 18dp line.
  static double labelFontSize() => 12;

  /// Caption line height for a grouped action, as a multiple of
  /// [labelFontSize].
  static const double labelHeight = 18 / 12;

  /// Corner radius of a [AppSwipeActionsStyle.separated] pill.
  static BorderRadius borderRadius() =>
      BorderRadius.circular(AppDimension.radiusMd);

  /// Corner radius of the whole [AppSwipeActionsStyle.grouped] strip, applied
  /// once around the group rather than per cell.
  ///
  /// Figma rounds the edge the row slides away from by 12 and the outer edge
  /// by the row's own 20 (`8487:31503`), which is what makes the strip read as
  /// part of the card rather than a tray behind it. Directional, so RTL
  /// mirrors without a locale branch.
  ///
  /// [rowRadius] is the card's own corner, supplied by the caller — the
  /// design system has no way to know what the row it is wrapping looks like.
  static BorderRadiusDirectional groupedBorderRadius({double? rowRadius}) =>
      BorderRadiusDirectional.horizontal(
        start: Radius.circular(responsiveDimension(12)),
        end: Radius.circular(rowRadius ?? responsiveDimension(20)),
      );

  static SwipeActionSurfaceColors resolve({
    required AppSwipeActionVariant variant,
    required AppColors colors,
    required bool enabled,
    AppSwipeActionsStyle style = AppSwipeActionsStyle.separated,
  }) {
    if (!enabled) {
      return SwipeActionSurfaceColors(
        background: colors.disabled,
        foreground: colors.onDisabled,
      );
    }

    return switch (variant) {
      // Grouped's neutral cell is Figma's `#F7F9FA` on `#5C6C75` — `sky/50`
      // and `sky/600` exactly (`8487:31450`). Separated's is the softer grey
      // the provider rows already ship; neither is more correct, they are two
      // designs.
      AppSwipeActionVariant.neutral => switch (style) {
        AppSwipeActionsStyle.separated => SwipeActionSurfaceColors(
          background: colors.gray100,
          foreground: colors.textPrimary,
        ),
        AppSwipeActionsStyle.grouped => SwipeActionSurfaceColors(
          background: colors.palettes.sky.shade50,
          foreground: colors.palettes.sky.shade600,
        ),
      },
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
