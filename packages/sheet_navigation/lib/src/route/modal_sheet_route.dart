import 'dart:ui' show lerpDouble;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:sheet_navigation/src/gesture/sheet_drag_controller.dart';
import 'package:sheet_navigation/src/presentation/widgets/sheet_scaffold.dart';
import 'package:sheet_navigation/src/route/sheet_route_settings.dart';
import 'package:sheet_navigation/src/route/sheet_transitions.dart';

/// A sheet presented as a real `PopupRoute` on the root navigator.
///
/// Distinct from `showModalBottomSheet`: because this is a route (not a
/// widget pushed onto an internal overlay stack managed by a helper
/// function), pushing a second `ModalSheetRoute` on top of a first one makes
/// the first one aware of it via `secondaryAnimation` — which this route uses
/// to morph itself to fullscreen (corners flatten, height grows to 100%)
/// while the new sheet slides up on top. Popping reverses the morph. This is
/// the LinkedIn-style nested-sheet effect.
///
/// Construct via `SheetNavigator`/`showSheet` rather than pushing directly.
class ModalSheetRoute<T> extends PopupRoute<T> {
  ModalSheetRoute({
    required this.builder,
    this.sheetSettings = const SheetRouteSettings(),
    RouteSettings? routeSettings,
  }) : super(settings: routeSettings);

  final WidgetBuilder builder;
  final SheetRouteSettings sheetSettings;

  @override
  bool get barrierDismissible => sheetSettings.isDismissible;

  @override
  Color? get barrierColor =>
      sheetSettings.barrierColor ?? OverlayTokens.scrimColor();

  @override
  String get barrierLabel => 'Dismiss';

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => SheetTransitions.enterDuration;

  @override
  Duration get reverseTransitionDuration => SheetTransitions.exitDuration;

  /// Exposes the route's own animation controller to the drag gesture
  /// handler. Only accessible here — `controller` is protected on
  /// [TransitionRoute] and cannot be read from outside this class.
  AnimationController get sheetAnimationController => controller!;

  void dismiss() {
    if (isCurrent && navigator != null) {
      navigator!.pop();
    }
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _ModalSheetContent<T>(
      route: this,
      animation: animation,
      secondaryAnimation: secondaryAnimation,
    );
  }
}

class _ModalSheetContent<T> extends StatefulWidget {
  const _ModalSheetContent({
    required this.route,
    required this.animation,
    required this.secondaryAnimation,
  });

  final ModalSheetRoute<T> route;
  final Animation<double> animation;
  final Animation<double> secondaryAnimation;

  @override
  State<_ModalSheetContent<T>> createState() => _ModalSheetContentState<T>();
}

class _ModalSheetContentState<T> extends State<_ModalSheetContent<T>> {
  late final SheetDragController _drag;

  ModalSheetRoute<T> get _route => widget.route;
  SheetRouteSettings get _settings => _route.sheetSettings;

  @override
  void initState() {
    super.initState();
    _drag = SheetDragController(
      controller: _route.sheetAnimationController,
      snapFractions: _settings.snapFractions,
      onDismiss: _route.dismiss,
    );
  }

  /// Handles a system-back / predictive-back intent that reached this sheet.
  ///
  /// The sheet always reports `canPop: false` (see [build]) so the framework
  /// treats it — the top-most route on the root navigator — as the owner of
  /// the back gesture. That guarantees the intent is consumed here and never
  /// forwarded to (or interpreted as a pop of) the underlying page's
  /// navigator, which is the SAN sheet/back bug: the underlying route would
  /// navigate away while the root-level sheet stayed mounted.
  ///
  /// A dismissible sheet closes itself in response (matching the Android
  /// bottom-sheet convention that back dismisses the sheet); a non-dismissible
  /// sheet swallows the intent entirely. Either way the underlying route is
  /// left untouched. Drag-to-dismiss and explicit `SheetNavigator.pop` call
  /// `Navigator.pop` directly, which bypasses [PopScope], so they are
  /// unaffected.
  void _onSystemBack(bool didPop) {
    if (didPop) return;
    if (_route.sheetSettings.isDismissible) _route.dismiss();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final spec = BottomSheetTokens.resolve(
      colors: context.appColors,
      typography: context.appTypography,
      brightness: brightness,
    );

    final screenHeight = MediaQuery.sizeOf(context).height;

    // Rest-state (morphT == 0) min/max height in pixels. Both modes are
    // expressed as a [min, max] range so the morph below can lerp either
    // one uniformly toward the full screen height:
    //  - expanded: a fixed extent — min == max == restingFraction * screen.
    //  - content: a real range — [minHeight, maxHeightFactor * screen] —
    //    the child (via SheetScaffold's Flexible(loose)) sizes itself
    //    anywhere inside it.
    final double restMin;
    final double restMax;
    if (_settings.sheetSize == SheetSize.expanded) {
      final restingFraction =
          _settings.initialHeightFraction ?? _settings.largestSnapFraction;
      restMin = restMax = restingFraction.clamp(0.0, 1.0) * screenHeight;
    } else {
      restMin = _settings.minHeight ?? 0;
      restMax = _settings.maxHeightFactor * screenHeight;
    }

    final enterCurved = CurvedAnimation(
      parent: widget.animation,
      curve: SheetTransitions.enterCurve,
      reverseCurve: SheetTransitions.exitCurve,
    );
    final morphCurved = _settings.expandPreviousToFullscreen
        ? CurvedAnimation(
            parent: widget.secondaryAnimation,
            curve: SheetTransitions.morphCurve,
          )
        : const AlwaysStoppedAnimation<double>(0);

    return PopScope(
      // Always false: the sheet is the top-most route on the root navigator,
      // so it must be the authoritative back handler. Reporting canPop:false
      // makes the framework route the system/predictive back intent to
      // [_onSystemBack] instead of letting it fall through and pop the
      // underlying page's (possibly nested) navigator.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) => _onSystemBack(didPop),
      child: AnimatedBuilder(
        animation: Listenable.merge([enterCurved, morphCurved]),
        builder: (context, child) {
          final morphT = morphCurved.value;
          // As morphT -> 1 (a child sheet is pushed on top), both bounds
          // widen toward the full screen height, forcing this sheet to
          // fullscreen regardless of sheetSize.
          final currentMin = lerpDouble(restMin, screenHeight, morphT)!;
          final currentMax = lerpDouble(restMax, screenHeight, morphT)!;
          final radius = SheetTransitions.lerpRadius(spec.topRadius, morphT);

          return Align(
            alignment: Alignment.bottomCenter,
            child: FractionalTranslation(
              translation: Offset(0, 1 - enterCurved.value),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: currentMin,
                  maxHeight: currentMax,
                ),
                child: SheetScaffold(
                  radius: radius,
                  title: _settings.title,
                  padChild: _settings.padChild,
                  sheetSize: _settings.sheetSize,
                  showDragHandle: _settings.enableDrag,
                  enableDrag: _settings.enableDrag,
                  useSafeArea: _settings.useSafeArea,
                  onVerticalDragUpdate: (details) => _drag.onDragUpdate(
                    details,
                    MediaQuery.sizeOf(context).height,
                  ),
                  onVerticalDragEnd: (details) => _drag.onDragEnd(
                    details,
                    MediaQuery.sizeOf(context).height,
                  ),
                  child: child!,
                ),
              ),
            ),
          );
        },
        child: Builder(builder: _route.builder),
      ),
    );
  }
}
