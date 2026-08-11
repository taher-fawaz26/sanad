import 'package:auth/src/domain/entities/auth_response_entity.dart';
import 'package:auth/src/session/session_cache.dart';
import 'package:auth/src/session/session_storage.dart';
import 'package:network/network.dart';

/// Orchestrates the three-tier session persistence: memory ([SessionCache]),
/// disk ([SessionStorage], encrypted Hive box), and tokens
/// ([TokenManager], SecureStorage).
///
/// Writes fan out to all three tiers in the correct order:
/// tokens first (so any request racing the save can use them), then Hive
/// (so a crash mid-save still recovers), then memory (so listeners see the
/// change last, when everything is consistent).
///
/// Reads are memory-first. [restore] rehydrates memory from Hive at startup;
/// callers must invoke it once during boot (after DI, before splash checks).
class SessionRepository {
  SessionRepository({
    required SessionCache cache,
    required SessionStorage storage,
    required TokenManager tokenManager,
  }) : _cache = cache,
       _storage = storage,
       _tokenManager = tokenManager;

  final SessionCache _cache;
  final SessionStorage _storage;
  final TokenManager _tokenManager;

  /// Persist a brand-new session (login / OTP / registration / Google).
  /// Tokens go to SecureStorage first, then Hive, then memory.
  Future<void> save(AuthSessionEntity session) async {
    await _tokenManager.saveTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    await _storage.write(session);
    _cache.set(session);
  }

  /// Update an existing session in-place — tokens only re-persisted if the
  /// builder actually changed them. Used for post-login mutations such as
  /// change-email/phone/language, profile updates, etc.
  ///
  /// Returns `null` and no-ops when there is no active session.
  Future<AuthSessionEntity?> update(
    AuthSessionEntity Function(AuthSessionEntity current) builder,
  ) async {
    final existing = _cache.value;
    if (existing == null) return null;

    final next = builder(existing);
    // Only touch SecureStorage if the tokens actually rotated — normal
    // mutations (accountSettings, profile) don't need a token write.
    if (next.accessToken != existing.accessToken ||
        next.refreshToken != existing.refreshToken) {
      await _tokenManager.saveTokens(
        accessToken: next.accessToken,
        refreshToken: next.refreshToken,
      );
    }
    await _storage.write(next);
    _cache.set(next);
    return next;
  }

  /// Rehydrate memory from Hive at startup. If Hive has a snapshot but the
  /// tokens are missing from SecureStorage, or vice-versa, the session is
  /// discarded and treated as signed-out — the two must stay in lockstep.
  ///
  /// Returns the restored session, or `null` if none was recovered.
  Future<AuthSessionEntity?> restore() async {
    final persisted = await _storage.read();
    if (persisted == null) return null;

    final accessToken = _tokenManager.accessToken;
    final refreshToken = _tokenManager.refreshToken;
    if (accessToken == null ||
        accessToken.isEmpty ||
        refreshToken == null ||
        refreshToken.isEmpty) {
      // Tokens were cleared without clearing the session snapshot — treat as
      // signed-out and drop the orphan snapshot.
      await _storage.delete();
      return null;
    }

    // Compose live tokens (in case the persisted snapshot is behind after a
    // silent refresh on a previous run).
    final session = persisted.copyWith(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    _cache.set(session);
    return session;
  }

  /// Wipe every tier. Order chosen so a crash mid-clear cannot leave an
  /// exploitable state: tokens (kill server access first) → Hive session
  /// (kill on-disk copy) → memory.
  Future<void> clear() async {
    await _tokenManager.clearTokens();
    await _storage.delete();
    _cache.clear();
  }
}
