import 'package:account_settings/src/domain/enums/app_lock_state.dart';
import 'package:account_settings/src/presentation/lock/app_lock_controller.dart';
import 'package:account_settings/src/presentation/lock/app_lock_screen.dart';
import 'package:auth/auth.dart' show AuthLogoutUseCase, SessionManager;
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Wraps the routed app in the local authentication gate.
///
/// Place this directly around `MaterialApp.router`. While the gate is shut it
/// renders the lock screen **in place of** [child] rather than over it, so no
/// protected widget is built, and nothing routed can be reached, before the
/// user has authenticated.
///
/// Sitting above the router — rather than inside a `redirect` — keeps the gate
/// out of `AuthStatusNotifier` (which drives both apps' routers and the RBAC
/// table) and leaves deep links intact: the `GoRouter` instance is owned by
/// the app and outlives this widget, so the pending location is still there
/// when [child] is remounted.
class AppLockGate extends StatefulWidget {
  const AppLockGate({
    required this.controller,
    required this.child,
    super.key,
    this.themeMode = ThemeMode.system,
    this.onLogout,
    this.localizationsDelegates,
    this.supportedLocales = const [Locale('en', 'US')],
    this.locale,
  });

  final AppLockController controller;

  /// The routed app, built only while the gate is open.
  final Widget child;

  final ThemeMode themeMode;

  /// Localization wiring for the barrier's own [MaterialApp].
  ///
  /// Passed in rather than read from an `EasyLocalization` ancestor so this
  /// widget can be pumped on its own in a test. The apps forward the same
  /// values they give `MaterialApp.router`.
  final Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates;

  final Iterable<Locale> supportedLocales;

  final Locale? locale;

  /// Overrides the lock screen's logout action. Defaults to the same terminal
  /// effect as `AuthLogoutEvent`: revoke server-side, then wipe the session
  /// (which flips `AuthStatusNotifier` and redirects to Login).
  final Future<void> Function()? onLogout;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> {
  @override
  void initState() {
    super.initState();
    // Resolves AppLockState.unknown. Not awaited: the neutral frame below
    // renders meanwhile, so the gate never blocks startup.
    widget.controller.initialize().ignore();
  }

  Future<void> _logout() async {
    final override = widget.onLogout;
    if (override != null) return override();

    // Best-effort server revocation, then an unconditional local wipe — the
    // same order AuthBloc uses, so a network failure still logs the user out.
    await sl<AuthLogoutUseCase>()(const NoParams()).run();
    await sl<SessionManager>().clear();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        if (widget.controller.isOpen) return widget.child;
        return _buildBarrier(context);
      },
    );
  }

  /// The barrier runs in its own minimal [MaterialApp] — themed and localized,
  /// but with no router, so none of the app's routes exist while it is up.
  Widget _buildBarrier(BuildContext context) {
    final state = widget.controller.state;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: widget.localizationsDelegates,
      supportedLocales: widget.supportedLocales,
      locale: widget.locale,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: widget.themeMode,
      home: state == AppLockState.unknown
          // Preference and capability are not known yet. Show nothing and
          // raise no prompt — deciding either way here would be a guess.
          ? const ColoredBox(color: Colors.transparent)
          : AppLockScreen(
              busy: state == AppLockState.authenticating,
              lastFailure: widget.controller.lastFailure,
              onUnlock: () => widget.controller.authenticate().ignore(),
              onLogout: () => _logout().ignore(),
            ),
    );
  }
}
