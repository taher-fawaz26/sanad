import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:shared_ui/src/widgets/app_progress_dialog.dart';

/// App-wide gateway for MUTATION blocking progress.
///
/// Shows a single non-dismissible [AppProgressDialog] while a create / update /
/// delete request is in flight, blocking interaction with the screen behind it.
/// Prefer driving this through `MutationListener` rather than calling it
/// directly.
///
/// Lifecycle guarantees (the reason this is centralized instead of hand-rolled
/// per feature):
/// * **Idempotent** — a second [show] while already visible is a no-op, and
///   [dismiss] while hidden is a no-op. No per-feature visibility latch needed.
/// * **Exactly-once dismissal** — the dialog is tracked by the context of its
///   own route, so [dismiss] pops *that* route (not whatever happens to be on
///   top) and can never leave a stuck overlay.
/// * **Root navigator** — both show and dismiss target the root navigator, so
///   nested navigators / route changes don't desync show and dismiss.
abstract final class AppProgress {
  AppProgress._();

  static bool _isShown = false;
  static BuildContext? _dialogContext;

  /// True while the progress dialog is on screen. Exposed for tests.
  @visibleForTesting
  static bool get isShown => _isShown;

  /// Clears the tracked state WITHOUT popping a route. Test-only — use to
  /// reset the static latch between tests without touching a torn-down tree.
  @visibleForTesting
  static void reset() {
    _isShown = false;
    _dialogContext = null;
  }

  /// Shows the blocking progress dialog. No-op if already shown.
  static void show(
    BuildContext context, {
    required String title,
    String? description,
  }) {
    if (_isShown) return;
    _isShown = true;

    final barrierColor = context.appDialogTheme.spec.barrierColor;

    showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      barrierColor: barrierColor,
      builder: (dialogContext) {
        _dialogContext = dialogContext;
        return PopScope(
          canPop: false,
          child: AppProgressDialog(title: title, description: description),
        );
      },
    ).whenComplete(() {
      _isShown = false;
      _dialogContext = null;
    });
  }

  /// Dismisses the progress dialog if shown. No-op otherwise. Safe to call
  /// after route changes / disposal — it checks the dialog context is mounted.
  static void dismiss() {
    if (!_isShown) return;
    final dialogContext = _dialogContext;
    if (dialogContext != null && dialogContext.mounted) {
      Navigator.of(dialogContext).pop();
    }
    _isShown = false;
    _dialogContext = null;
  }
}
