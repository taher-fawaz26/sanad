import 'package:auth/auth.dart';
import 'package:core/core.dart';

/// Re-syncs the signed-in user's identity/permissions from `GET /me` on app
/// resume — the counterpart to the cold-start resync `AuthBloc` already
/// performs in `_checkSignInStatus`.
///
/// Without this, a permission or role change made elsewhere (e.g. an owner
/// editing a worker's role via Provider RBAC) never reaches an already-warm
/// app process: `FeatureModule.onAppResumed()` has no call sites anywhere in
/// the workspace, so nothing currently re-fetches `/me` after the initial
/// splash. A revoked permission would otherwise persist for the lifetime of
/// the process.
///
/// Deliberately NOT routed through `AuthBloc`: this is a silent background
/// sync with no user-facing loading/failure state, so it composes
/// [GetCurrentUserUseCase] and [SessionManager] directly — the same two
/// calls `_checkSignInStatus` makes, minus the state emissions.
class PermissionResync {
  /// Creates a [PermissionResync] over the app's existing [sessionManager]
  /// and [getCurrentUserUseCase] singletons — no new state of its own.
  const PermissionResync({
    required SessionManager sessionManager,
    required GetCurrentUserUseCase getCurrentUserUseCase,
  }) : _sessionManager = sessionManager,
       _getCurrentUserUseCase = getCurrentUserUseCase;

  final SessionManager _sessionManager;
  final GetCurrentUserUseCase _getCurrentUserUseCase;

  /// No-ops when signed out. Best-effort otherwise: a failed `/me` call
  /// (offline, transient 401 mid-refresh) leaves the last-known permission
  /// snapshot in place rather than surfacing an error — identical to the
  /// cold-start resync's failure handling.
  Future<void> call() async {
    if (!_sessionManager.isAuthenticated) return;

    final result = await _getCurrentUserUseCase(const NoParams()).run();
    await result.match((_) async {}, _sessionManager.hydrateIdentity);
  }
}
