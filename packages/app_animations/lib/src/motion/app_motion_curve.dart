import 'package:flutter/animation.dart';

/// The single source of truth for animation curves across the monorepo.
///
/// Every value here matches a curve already in live use somewhere in the
/// app (see each constant's doc) — this consolidates what used to be
/// `Curves.*` literals scattered across ~8 files with no shared vocabulary.
/// Do not reach for a raw `Curves.*` value in application code; if none of
/// these fit, that is a signal the motion needs design review, not a new
/// ad-hoc token.
abstract final class AppMotionCurve {
  AppMotionCurve._();

  /// Default curve for most implicit/explicit UI transitions (search field
  /// expand, segmented-control thumb, swipe-action hint, nav-bar collapse).
  static const Curve standard = Curves.easeInOut;

  /// A motion that starts fast and settles — collapse/scroll effects, a
  /// drag-release snap, an expand-in-place transition.
  static const Curve decelerated = Curves.easeOut;

  /// The reverse of [decelerated] — a motion that eases into a fast finish,
  /// paired with [decelerated] for a symmetric forward/reverse pair.
  static const Curve accelerated = Curves.easeIn;

  /// Material-style emphasized entrance — a sheet sliding/morphing in.
  static const Curve emphasizedDecelerate = Curves.easeOutCubic;

  /// Material-style emphasized exit — a sheet sliding out.
  static const Curve emphasizedAccelerate = Curves.easeInCubic;
}
