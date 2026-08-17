import 'package:auth/src/domain/entities/auth_response_entity.dart';
import 'package:auth/src/session/session_cache.dart';
import 'package:authorization/authorization.dart';
import 'package:flutter/foundation.dart';

/// The `auth` package's implementation of `AuthorizationReader` — the single
/// bridge between the existing session snapshot and the authorization
/// package's evaluator.
///
/// Deliberately NOT a new BLoC or a new cache: it holds no state of its own
/// beyond the last-computed [PermissionSet]/[isResolved] pair, purely so it
/// can decide whether a [SessionCache] mutation is decision-relevant before
/// calling [notifyListeners]. The session snapshot — including
/// [AuthSessionEntity.permissions] and [AuthSessionEntity.permissionsSyncedAt]
/// — remains the one source of truth; this class never diverges from it and
/// is cleared by the exact same [SessionCache.clear] path logout already uses.
///
/// Notifying only on a genuine change (not on every session mutation, e.g. a
/// language or profile edit) is what makes it safe to feed GoRouter's
/// `refreshListenable` without redirect churn — see the router integration
/// in `apps/sanad_provider`.
class AuthorizationSignal extends ChangeNotifier
    implements AuthorizationReader {
  AuthorizationSignal(this._cache) {
    _sync(initial: true);
    _cache.listenable.addListener(_onSessionChanged);
  }

  final SessionCache _cache;

  PermissionSet _permissions = PermissionSet.empty;
  bool _isResolved = false;

  @override
  PermissionSet get permissions => _permissions;

  @override
  bool get isResolved => _isResolved;

  void _onSessionChanged() => _sync();

  /// Recomputes the projection from the current session and notifies only
  /// if either half of it actually changed. [initial] skips the
  /// no-op-detecting comparison on construction, since there is no previous
  /// state to compare against and no listener could be attached yet anyway.
  void _sync({bool initial = false}) {
    final session = _cache.value;
    final nextPermissions = session == null
        ? PermissionSet.empty
        : PermissionSet.from(session.permissions.map((p) => p.name));
    final nextResolved = session?.permissionsSyncedAt != null;

    final changed =
        nextPermissions != _permissions || nextResolved != _isResolved;
    _permissions = nextPermissions;
    _isResolved = nextResolved;

    if (!initial && changed) {
      notifyListeners();
    }
  }

  @override
  bool can(String action) => _isResolved && _permissions.can(action);

  @override
  bool canAny(Iterable<String> actions) =>
      _isResolved && _permissions.canAny(actions);

  @override
  bool canAll(Iterable<String> actions) =>
      _isResolved && _permissions.canAll(actions);

  @override
  bool satisfies(PermissionRequirement requirement) =>
      _isResolved && requirement.isSatisfiedBy(_permissions);

  @override
  void dispose() {
    _cache.listenable.removeListener(_onSessionChanged);
    super.dispose();
  }
}
