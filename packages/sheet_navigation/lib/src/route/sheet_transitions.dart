import 'package:flutter/material.dart';

/// Curves and durations shared by every `ModalSheetRoute` transition.
///
/// Kept in one place so the enter/exit slide, the nested-sheet morph, and any
/// future transition all move in lockstep.
abstract final class SheetTransitions {
  SheetTransitions._();

  static const Duration enterDuration = Duration(milliseconds: 300);
  static const Duration exitDuration = Duration(milliseconds: 250);

  static const Curve enterCurve = Curves.easeOutCubic;
  static const Curve exitCurve = Curves.easeInCubic;

  /// Curve applied to `secondaryAnimation` when a child sheet morphs this
  /// sheet to fullscreen.
  static const Curve morphCurve = Curves.easeOutCubic;

  /// Interpolates the top corner radius from [radius] to 0 (fullscreen) as
  /// [t] goes 0 → 1.
  static BorderRadius lerpRadius(BorderRadius radius, double t) {
    return BorderRadius.lerp(radius, BorderRadius.zero, t)!;
  }
}
