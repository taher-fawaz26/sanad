import 'package:account_settings/src/domain/enums/app_lock_capability.dart';
import 'package:account_settings/src/domain/enums/app_lock_state.dart';
import 'package:account_settings/src/domain/repositories/app_lock_repository.dart';
import 'package:auth/auth.dart' show SessionManager;
import 'package:device/device.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';

/// Owns the local authentication gate.
///
/// One process-wide instance (a lazy singleton), shared by the gate widget and
/// the Security settings toggle so the two can never disagree.
///
/// This gate is a convenience layer **over** an already-authenticated session,
/// never a substitute for it. It is not consulted as evidence of backend
/// authentication, it never touches tokens, and every existing router
/// redirect, 401 refresh, and session transition runs unchanged underneath it.
class AppLockController extends ChangeNotifier {
  AppLockController({
    required AppLockRepository repository,
    required BiometricService biometrics,
    required SessionManager sessionManager,
    required bool featureEnabled,
  }) : _repository = repository,
       _biometrics = biometrics,
       _sessionManager = sessionManager,
       _featureEnabled = featureEnabled {
    _sessionManager.watch().addListener(_onSessionChanged);
  }

  final AppLockRepository _repository;
  final BiometricService _biometrics;
  final SessionManager _sessionManager;
  final bool _featureEnabled;

  AppLockState _state = AppLockState.unknown;
  BiometricAuthStatus? _lastFailure;

  /// Cached preference. Read once during [initialize] and updated only through
  /// [setEnabled], so lifecycle callbacks never hit storage.
  bool _enabled = false;
  AppLockCapability _capability = AppLockCapability.unsupported;

  /// The single in-flight authentication, or `null`. Doubles as the guard
  /// against concurrent `authenticate()` calls — a second caller receives the
  /// same future rather than raising a second OS prompt.
  Future<void>? _inFlight;

  /// Current gate state.
  AppLockState get state => _state;

  /// Whether protected content may render.
  ///
  /// [AppLockState.unknown] is deliberately *not* unlocked: nothing protected
  /// may be built before the preference and capability are known.
  bool get isOpen =>
      _state == AppLockState.unlocked || _state == AppLockState.unavailable;

  /// Status of the most recent unsuccessful attempt, used only to choose the
  /// message shown on the lock screen. `null` once an attempt succeeds.
  BiometricAuthStatus? get lastFailure => _lastFailure;

  /// Whether the lock preference is currently on.
  bool get isEnabled => _enabled;

  /// Whether this device can authenticate at all.
  AppLockCapability get capability => _capability;

  /// Resolves [AppLockState.unknown] into a real state.
  ///
  /// Safe to call more than once; a second call re-derives from the same
  /// inputs. Never awaited by bootstrap — the gate renders a neutral frame
  /// while this runs, so startup is not blocked.
  Future<void> initialize() async {
    if (!_featureEnabled) {
      _set(AppLockState.unlocked);
      return;
    }

    _enabled = await _repository.isEnabled();
    if (!_enabled || _sessionManager.current() == null) {
      _set(AppLockState.unlocked);
      return;
    }

    _capability = await _repository.capability();
    if (_capability != AppLockCapability.available) {
      // Fail open: the device can no longer authenticate anyone, so holding
      // the gate shut would brick the app for a user no credential can let in.
      _set(AppLockState.unavailable);
      return;
    }

    await _arm();
  }

  /// Raises the OS prompt.
  ///
  /// Called on a lock transition and from the lock screen's retry button —
  /// never from a `build` method.
  Future<void> authenticate() {
    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;
    if (_state != AppLockState.locked) return Future<void>.value();
    return _inFlight = _runAuthentication();
  }

  Future<void> _runAuthentication() async {
    _set(AppLockState.authenticating);
    try {
      final result = await _biometrics.authenticate(
        reason: 'settings.biometric_unlock_reason'.tr(),
        // Let the OS fall back to the device credential (PIN / pattern /
        // passcode). The gate must not depend on a specific biometric being
        // enrolled for correctness. Stated explicitly even though it
        // matches the default — it is a security decision, not an
        // incidental argument.
        // ignore: avoid_redundant_argument_values
        biometricOnly: false,
      );

      // The session can end while the prompt is on screen (logout from
      // another surface, a 401 refresh failure). Unlocking into a dead
      // session would be meaningless; the router has already redirected.
      if (_sessionManager.current() == null) {
        _lastFailure = null;
        _set(AppLockState.unlocked);
        return;
      }

      if (result.isSuccess) {
        _lastFailure = null;
        _set(AppLockState.unlocked);
      } else {
        // Any non-success keeps the gate shut. `local_auth` cannot tell a
        // cancellation from a failed match, so this branch deliberately makes
        // no claim about which happened — it only records the status so the
        // lock screen can pick its copy. There is no auto-retry: the user
        // must press Unlock, which is what stops a prompt loop.
        _lastFailure = result.status;
        _set(AppLockState.locked);
      }
    } finally {
      _inFlight = null;
    }
  }

  /// Arms the gate when the app leaves the foreground.
  ///
  /// Locking on *pause* rather than resume means the lock screen is already in
  /// place before the OS takes its app-switcher snapshot, and makes repeated
  /// resume events harmless.
  void onAppPaused() {
    if (!_canGate) return;
    if (_state == AppLockState.unlocked) _set(AppLockState.locked);
  }

  /// Re-raises the prompt when the app returns to the foreground still locked.
  ///
  /// Idempotent: a duplicate `resumed` event, or a resume that arrives while a
  /// prompt is already up, is absorbed by [authenticate]'s guard.
  void onAppResumed() {
    if (!_canGate) return;
    if (_state == AppLockState.locked) authenticate().ignore();
  }

  /// Applies a preference change made from Security settings.
  ///
  /// Only ever called after the corresponding local authentication has
  /// succeeded — see `SecurityBloc`.
  Future<void> setEnabled({required bool enabled}) async {
    await _repository.setEnabled(enabled: enabled);
    _enabled = enabled;
    if (!enabled) {
      _lastFailure = null;
      _set(AppLockState.unlocked);
      return;
    }
    // Capability is only probed during initialize() when the lock was already
    // on. Switching it on mid-session must probe too, otherwise `_canGate`
    // would stay false and the gate would never arm again for this process.
    _capability = await _repository.capability();
  }

  /// Whether the gate has anything to do right now.
  bool get _canGate =>
      _featureEnabled &&
      _enabled &&
      _capability == AppLockCapability.available &&
      _sessionManager.current() != null;

  /// Shuts the gate and raises the first prompt.
  ///
  /// Awaited by [initialize] so that a completed `initialize()` always leaves
  /// a settled state rather than one still mid-prompt.
  Future<void> _arm() async {
    _set(AppLockState.locked);
    await authenticate();
  }

  void _onSessionChanged() {
    // A cleared session (logout, or a refresh failure that wiped it) leaves
    // nothing to protect. Holding the lock screen up over a logged-out app
    // would trap the user behind a gate with no purpose.
    if (_sessionManager.current() == null && _state != AppLockState.unlocked) {
      _lastFailure = null;
      _set(AppLockState.unlocked);
    }
  }

  void _set(AppLockState next) {
    if (_state == next) return;
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _sessionManager.watch().removeListener(_onSessionChanged);
    super.dispose();
  }
}
