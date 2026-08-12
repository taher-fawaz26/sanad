import 'package:flutter/widgets.dart';

/// Exposes the app shell's shared [ScrollController] to tab pages so their
/// primary scroll view can drive a hide-on-scroll bottom navigation bar
/// (e.g. wrapped in `Hidable`) from the app shell.
///
/// The app shell provides this above its `StatefulNavigationShell`; feature
/// packages attach their scroll view to it without depending on the app:
/// ```dart
/// ListView(controller: MainNavScrollController.of(context), ...)
/// ```
class MainNavScrollController extends InheritedWidget {
  /// Creates the inherited scroll controller.
  const MainNavScrollController({
    required this.controller,
    required super.child,
    super.key,
  });

  /// The shell's shared scroll controller.
  final ScrollController controller;

  /// Resolves the shell's shared scroll controller from [context], or
  /// `null` when this page isn't hosted inside a shell that provides one
  /// (e.g. reached via a push outside the shell).
  static ScrollController? maybeOf(BuildContext context) {
    final widget = context
        .dependOnInheritedWidgetOfExactType<MainNavScrollController>();
    return widget?.controller;
  }

  @override
  bool updateShouldNotify(MainNavScrollController oldWidget) =>
      controller != oldWidget.controller;
}
