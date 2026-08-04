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
    return Navigator.of(context, rootNavigator: true).push<T>(
      ModalSheetRoute<T>(builder: (_) => child, sheetSettings: settings),
    );
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
