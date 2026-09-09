import 'dart:async';

import 'package:app_logger/app_logger.dart';
import 'package:notifications/src/domain/enums/device_platform.dart';
import 'package:notifications/src/domain/services/push_messaging_gateway.dart';
import 'package:notifications/src/domain/usecases/register_device_usecase.dart';
import 'package:notifications/src/domain/usecases/unregister_device_usecase.dart';
import 'package:storage/storage.dart';

/// The **single owner** of push-token registration.
///
/// Registration is an upsert, not a setup step, so this runs on four triggers:
/// after every login, on every launch while still signed in, whenever the SDK
/// rotates the token, and once more (as a delete) immediately before logout.
///
/// Two invariants this class exists to hold:
///
/// * **Exactly one token-refresh subscription per app run.** [start] is
///   idempotent, so a re-entered bootstrap or a second module `initialize()`
///   cannot produce duplicate registration callbacks.
/// * **The last registered token is persisted.** Unregistering at logout has to
///   delete the token the *server* holds. Asking the SDK at that moment can
///   return a newly rotated value, or nothing at all, which would leave the old
///   token registered and quietly forward the next user's notifications.
class PushRegistrationCoordinator {
  PushRegistrationCoordinator({
    required PushMessagingGateway gateway,
    required RegisterDeviceUseCase registerDevice,
    required UnregisterDeviceUseCase unregisterDevice,
    required LocalStorage storage,
    DevicePlatform Function() resolvePlatform = DevicePlatform.current,
  }) : _gateway = gateway,
       _registerDevice = registerDevice,
       _unregisterDevice = unregisterDevice,
       _storage = storage,
       _resolvePlatform = resolvePlatform;

  static const String _storageKey = 'push_registered_token';

  final PushMessagingGateway _gateway;
  final RegisterDeviceUseCase _registerDevice;
  final UnregisterDeviceUseCase _unregisterDevice;
  final LocalStorage _storage;
  final DevicePlatform Function() _resolvePlatform;

  StreamSubscription<String>? _refreshSubscription;

  /// Begins listening for token rotations. Idempotent.
  void start() {
    if (_refreshSubscription != null) return;
    _refreshSubscription = _gateway.onTokenRefresh.listen(
      (token) => _register(token).ignore(),
      onError: (Object error) =>
          appLogger.w('Push token refresh stream failed: $error'),
    );
  }

  /// Registers the current token.
  ///
  /// Call after a successful sign-in and on every launch with a live session.
  /// Never throws: push is an enhancement, and a failure here must not affect
  /// the flow that triggered it.
  Future<void> syncRegistration() async {
    try {
      final token = await _gateway.getToken();
      if (token == null || token.isEmpty) {
        // Normal on iOS before the APNs token lands — the refresh stream will
        // deliver it shortly and `start()` re-registers then.
        appLogger.i('No push token yet; deferring registration.');
        return;
      }
      await _register(token);
    } on Object catch (error) {
      appLogger.w('Push registration failed: $error');
    }
  }

  /// Deletes the registered token, so a signed-out handset stops receiving the
  /// next user's notifications.
  ///
  /// Must run **before** the session is cleared, while the bearer token is
  /// still live. Swallows every failure: logout can never be blocked by this.
  ///
  /// **Only a token this coordinator actually registered is deleted.** It
  /// deliberately does not fall back to asking the SDK: `clear()` on
  /// `SessionManager` also runs on a 401-refresh failure and on a signed-out
  /// cold start, and a
  /// fallback would fire an unauthenticated `DELETE` on every one of those —
  /// which the backend answers `401`, then `429` once they pile up. If nothing
  /// was registered, the server holds no token for this device and there is
  /// nothing to delete.
  Future<void> unregister() async {
    try {
      final token = await _lastRegisteredToken();
      if (token == null || token.isEmpty) return;
      final result = await _unregisterDevice(token).run();
      result.match(
        (failure) =>
            appLogger.w('Push unregistration failed: ${failure.message}'),
        (_) => appLogger.i('Push token unregistered.'),
      );
    } on Object catch (error) {
      appLogger.w('Push unregistration failed: $error');
    } finally {
      // Forget it either way. A token we could not delete is one we must not
      // try to delete again under the next user's credentials.
      await _storage.delete(key: _storageKey);
    }
  }

  /// Stops listening. Safe to call more than once.
  Future<void> dispose() async {
    await _refreshSubscription?.cancel();
    _refreshSubscription = null;
  }

  Future<void> _register(String token) async {
    final result = await _registerDevice(
      RegisterDeviceParams(token: token, platform: _resolvePlatform()),
    ).run();
    await result.match(
      (failure) async =>
          appLogger.w('Push registration failed: ${failure.message}'),
      (_) async => _storage.save(key: _storageKey, value: token),
    );
  }

  Future<String?> _lastRegisteredToken() async {
    final raw = await _storage.load(key: _storageKey);
    return raw is String && raw.isNotEmpty ? raw : null;
  }
}
