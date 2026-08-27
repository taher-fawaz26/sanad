import 'package:app_animations/app_animations.dart';
import 'package:flutter/material.dart';

/// Curves and durations shared by every `ModalSheetRoute` transition.
///
/// Kept in one place so the enter/exit slide, the nested-sheet morph, and any
/// future transition all move in lockstep. Sourced from the shared motion
/// vocabulary (`app_animations`) where the sheet's own timing coincides with
/// it; [exitDuration] is a deliberately asymmetric bespoke value (see its
/// own doc) with no equivalent token.
abstract final class SheetTransitions {
  SheetTransitions._();

  static const Duration enterDuration = AppMotionDuration.normal;

  /// Intentionally distinct from [enterDuration]/[AppMotionDuration.normal]
  /// — sheets exit a little faster than they enter, an asymmetric
  /// enter/exit feel with no equivalent in the generic motion vocabulary.
  static const Duration exitDuration = Duration(milliseconds: 250);

  static const Curve enterCurve = AppMotionCurve.emphasizedDecelerate;
  static const Curve exitCurve = AppMotionCurve.emphasizedAccelerate;

  /// Curve applied to `secondaryAnimation` when a child sheet morphs this
  /// sheet to fullscreen.
  static const Curve morphCurve = AppMotionCurve.emphasizedDecelerate;

  /// Interpolates the top corner radius from [radius] to 0 (fullscreen) as
  /// [t] goes 0 → 1.
  static BorderRadius lerpRadius(BorderRadius radius, double t) {
    return BorderRadius.lerp(radius, BorderRadius.zero, t)!;
  }
}
