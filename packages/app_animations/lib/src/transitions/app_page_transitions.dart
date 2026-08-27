import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

/// The single page-transition strategy for the app.
///
/// Applied via `ThemeData.pageTransitionsTheme` (see `AppTheme` in
/// `design_system`), which every `MaterialPage` route picks up
/// automatically — including every `GoRoute.builder` route in both apps —
/// with no per-route wiring. This is a deliberately global, one-line
/// integration point rather than a per-route rewrite.
///
/// `ModalSheetRoute` (package:sheet_navigation) is a `PopupRoute`, not a
/// `MaterialPage`, so it is unaffected by this theme — sheets keep using
/// `SheetTransitions`' own curves/durations, and there is no double
/// animation between the two.
///
/// Route navigation is functional motion (it communicates "you moved to a
/// new screen") — like the platform's own default transitions, it is
/// intentionally NOT suppressed by `AppMotion.reduceMotionOf`/reduced
/// motion, matching Material's own guidance that essential navigational
/// motion is preserved even when decorative motion is reduced.
abstract final class AppPageTransitions {
  AppPageTransitions._();

  /// Shared-axis (horizontal) forward navigation on the two platforms these
  /// apps actually ship to — a consistent cross-platform feel instead of
  /// the default per-platform mix (Cupertino slide vs. Android
  /// zoom/fade-through). Other [TargetPlatform]s keep Flutter's own
  /// default (irrelevant to `sanad_client`/`sanad_provider`, which are
  /// mobile-only).
  static const PageTransitionsTheme theme = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: SharedAxisPageTransitionsBuilder(
        transitionType: SharedAxisTransitionType.horizontal,
      ),
      TargetPlatform.iOS: SharedAxisPageTransitionsBuilder(
        transitionType: SharedAxisTransitionType.horizontal,
      ),
    },
  );
}
