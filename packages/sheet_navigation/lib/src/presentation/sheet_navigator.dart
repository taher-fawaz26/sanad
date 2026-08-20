import 'package:flutter/widgets.dart';
import 'package:sheet_navigation/src/route/modal_sheet_route.dart';
import 'package:sheet_navigation/src/route/sheet_route_settings.dart';

/// Facade over `Navigator` for pushing/popping `ModalSheetRoute`s.
///
/// Feature code never constructs a route directly — call
/// `SheetNavigator.push(context, child)` and treat the result like any other
/// awaited navigation call.
abstract final class SheetNavigator {
  SheetNavigator._();

  static Future<T?> push<T>(
    BuildContext context,
    Widget child, {
    SheetRouteSettings settings = const SheetRouteSettings(),
  }) {
    final rootNav = Navigator.of(context, rootNavigator: true);
    final sheetRoute = ModalSheetRoute<T>(
      builder: (_) => child,
      sheetSettings: settings,
    );

    _dismissSheetWhenParentPops(context, rootNav, sheetRoute);

    return rootNav.push<T>(sheetRoute);
  }

  static Future<T?> replace<T>(
    BuildContext context,
    Widget child, {
    SheetRouteSettings settings = const SheetRouteSettings(),
  }) {
    return Navigator.of(context, rootNavigator: true).pushReplacement<T, T>(
      ModalSheetRoute<T>(builder: (_) => child, sheetSettings: settings),
    );
  }

  static void pop<T extends Object?>(BuildContext context, [T? result]) {
    Navigator.of(context, rootNavigator: true).pop<T>(result);
  }

  static bool canPop(BuildContext context) {
    return Navigator.of(context, rootNavigator: true).canPop();
  }

  /// Auto-dismiss [sheetRoute] when the page that opened it is popped.
  ///
  /// The sheet lives on the root navigator; the calling page may be on a
  /// nested navigator (e.g. go_router's ShellRoute). A swipe-back pops the
  /// nested route but leaves the root-level sheet orphaned. This listener
  /// bridges the gap.
  static void _dismissSheetWhenParentPops<T>(
    BuildContext context,
    NavigatorState rootNav,
    ModalSheetRoute<T> sheetRoute,
  ) {
    final parentRoute = ModalRoute.of(context);
    if (parentRoute == null) return;

    late final void Function(AnimationStatus) listener;
    listener = (status) {
      if (status != AnimationStatus.reverse) return;
      parentRoute.animation?.removeStatusListener(listener);
      if (sheetRoute.isActive && sheetRoute.isCurrent) {
        rootNav.removeRoute(sheetRoute);
      }
    };
    parentRoute.animation?.addStatusListener(listener);

    // Clean up the listener if the sheet is dismissed normally (user taps
    // outside, drags down, or pops programmatically) before the parent
    // route is ever popped.
    sheetRoute.completed.then((_) {
      parentRoute.animation?.removeStatusListener(listener);
    });
  }
}

/// Convenience wrapper for a one-off sheet, mirroring `showModalBottomSheet`
/// call sites so migration is a near drop-in replacement.
Future<T?> showSheet<T>(
  BuildContext context, {
  required Widget child,
  SheetRouteSettings settings = const SheetRouteSettings(),
}) {
  return SheetNavigator.push<T>(context, child, settings: settings);
}
