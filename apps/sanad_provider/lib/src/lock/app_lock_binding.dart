import 'package:account_settings/account_settings.dart';
import 'package:flutter/widgets.dart';

/// Feeds app lifecycle transitions to the local authentication gate.
///
/// App-local by design, mirroring `PermissionResync`: the shared state machine
/// lives in `account_settings`, and each app owns only the wiring from its own
/// single [WidgetsBindingObserver].
///
/// Only [AppLifecycleState.paused] and [AppLifecycleState.resumed] are acted
/// on. `inactive` and `hidden` are deliberately ignored — the biometric sheet
/// itself drives the app inactive on iOS, so treating that as "left the
/// foreground" would re-lock the app that is currently showing the unlock
/// prompt, and the prompt would fight itself.
class AppLockBinding {
  /// Creates a binding over the app-wide [AppLockController] singleton.
  const AppLockBinding(this._controller);

  final AppLockController _controller;

  /// Routes a lifecycle event to the gate. Safe to call for every state.
  void onLifecycleStateChanged(AppLifecycleState state) {
    switch (state) {
      // Arm on the way out, not on the way back in: the lock screen is then
      // already in place before the OS captures its app-switcher snapshot,
      // and duplicate resume events cannot each raise a prompt.
      case AppLifecycleState.paused:
        _controller.onAppPaused();
      case AppLifecycleState.resumed:
        _controller.onAppResumed();
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        break;
    }
  }
}
