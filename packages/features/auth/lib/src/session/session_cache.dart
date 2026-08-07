import 'package:auth/src/domain/entities/auth_response_entity.dart';
import 'package:flutter/foundation.dart';

/// In-memory, reactive holder of the current [AuthSessionEntity].
///
/// The primary runtime source of truth for authenticated-user state — Hive
/// restores it on cold start and every write path (login, OTP, refresh,
/// partial updates) goes through here first. The [listenable] is what
/// widgets and routers observe to react to session changes without polling.
class SessionCache {
  SessionCache();

  final ValueNotifier<AuthSessionEntity?> _notifier =
      ValueNotifier<AuthSessionEntity?>(null);

  /// Current session, or `null` when the user is signed out.
  AuthSessionEntity? get value => _notifier.value;

  /// Reactive handle for observers (routers, widgets).
  ValueListenable<AuthSessionEntity?> get listenable => _notifier;

  /// Replaces the current session. Standard [ValueNotifier] semantics —
  /// listeners are notified when the new value is unequal to the old
  /// ([AuthSessionEntity] is [Equatable], so equality is by field values).
  void set(AuthSessionEntity session) {
    _notifier.value = session;
  }

  /// Clears the current session and notifies listeners.
  void clear() {
    _notifier.value = null;
  }

  void dispose() => _notifier.dispose();
}
