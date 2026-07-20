import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:network/src/connectivity/connectivity_controller.dart';
import 'package:network/src/connectivity/connectivity_offline_binder.dart';

/// Drop-in wrapper that surfaces [offlinePath] as a **pushed** route whenever
/// the device goes offline and pops it once connectivity returns.
///
/// Pushing (rather than replacing) preserves the navigation stack: the user
/// can pop the offline screen to keep browsing cached content, and it
/// re-appears automatically on the next connectivity drop.
///
/// Composes [ConnectivityOfflineBinder] so the router push/pop lives in one
/// place instead of being reimplemented per app.
class ConnectivityOfflineGate extends StatelessWidget {
  const ConnectivityOfflineGate({
    required this.controller,
    required this.router,
    required this.child,
    this.offlinePath = '/offline',
    super.key,
  });

  final ConnectivityController controller;
  final GoRouter router;

  /// Route path to push while offline. Defaults to `/offline`.
  final String offlinePath;

  final Widget child;

  void _pushOffline() {
    if (router.state.uri.path == offlinePath) return;
    router.push(offlinePath);
  }

  void _popOffline() {
    while (router.canPop() && router.state.uri.path == offlinePath) {
      router.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConnectivityOfflineBinder(
      controller: controller,
      onWentOffline: _pushOffline,
      onWentOnline: _popOffline,
      child: child,
    );
  }
}
