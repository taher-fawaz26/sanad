import 'package:account_settings/src/domain/enums/app_lock_capability.dart';

/// Persistence and capability facts backing the local authentication gate.
///
/// Stores only the user's *preference*. No biometric data, fingerprint
/// template, Face ID data, PIN, or passcode is ever read or written — those
/// belong to the OS and never reach the app.
abstract class AppLockRepository {
  /// Whether the user has switched the lock on.
  Future<bool> isEnabled();

  /// Persists the preference.
  ///
  /// Callers must only pass `enabled: true` **after** a successful local
  /// authentication — see `SecurityBloc`.
  Future<void> setEnabled({required bool enabled});

  /// Whether the post-login "turn on unlock?" offer has already been answered,
  /// either way. Keeps a user who chose "Not now" from being asked again.
  Future<bool> hasBeenOffered();

  /// Records that the offer was answered.
  Future<void> markOffered();

  /// Removes every stored lock preference.
  Future<void> clear();

  /// What this device is capable of, memoised for the process lifetime.
  Future<AppLockCapability> capability();
}
