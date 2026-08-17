import 'package:auth/src/data/models/responses/auth_session_response_dto.dart';
import 'package:auth/src/domain/entities/auth_response_entity.dart';
import 'package:storage/storage.dart';

/// Persistent adapter for the authenticated [AuthSessionEntity].
///
/// Serialises the whole session (tokens, user, profile, accountSettings,
/// permissions) as a JSON map via [AuthSessionResponseModel.toJson] into an
/// encrypted Hive box ([HiveBoxes.session], AES-GCM key stored in the
/// platform Keystore/Keychain). Uses the existing [HiveLocalStorage] — no
/// TypeAdapter or code generation required.
///
/// Tokens are persisted here for a lossless round-trip, but
/// [SessionManager.current] always overrides them with the live values from
/// [TokenManager] so they never go stale after a silent refresh.
class SessionStorage {
  SessionStorage(this._storage);

  final HiveLocalStorage _storage;

  static const String _sessionKey = 'session';

  /// Reads the persisted session, or `null` if none is stored or the payload
  /// is unparseable. A parse failure returns `null` (best-effort restore) so
  /// a stale/incompatible snapshot from an older app version cannot brick
  /// startup — the user simply lands on Login and re-authenticates.
  Future<AuthSessionEntity?> read() async {
    final raw = await _storage.load(
      key: _sessionKey,
      boxName: HiveBoxes.session,
    );
    if (raw == null) return null;
    if (raw is! Map) return null;
    try {
      return AuthSessionResponseModel.fromJson(
        Map<String, dynamic>.from(raw),
      );
    } on Object catch (_) {
      // Schema drift or a corrupt entry: swallow and force a re-login rather
      // than crashing the splash screen.
      return null;
    }
  }

  /// Persists [session] as a JSON map, overwriting any previous entry.
  Future<void> write(AuthSessionEntity session) async {
    final map = _toJson(session);
    await _storage.save(
      key: _sessionKey,
      value: map,
      boxName: HiveBoxes.session,
    );
  }

  /// Deletes the persisted session, if any.
  Future<void> delete() async {
    await _storage.delete(
      key: _sessionKey,
      boxName: HiveBoxes.session,
    );
  }

  /// Serialises [session] via [AuthSessionResponseModel]. The
  /// [AuthSessionResponseModel.toJson] path expects child objects (`user`,
  /// `profile`, `accountSettings`, `permissions` entries) to be their concrete
  /// model types — always true here because sessions only ever arrive from
  /// `AuthResponseModel.fromJson` or through `copyWith` (which reuses
  /// existing model instances).
  Map<String, dynamic> _toJson(AuthSessionEntity session) {
    final asModel = AuthSessionResponseModel(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      status: session.status,
      isEmailVerified: session.isEmailVerified,
      isProfileCreated: session.isProfileCreated,
      user: session.user,
      permissions: session.permissions,
      profile: session.profile,
      accountSettings: session.accountSettings,
      permissionsSyncedAt: session.permissionsSyncedAt,
    );
    return asModel.toJson();
  }
}
