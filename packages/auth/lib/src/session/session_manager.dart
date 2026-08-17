import 'package:auth/src/auth/auth_status.dart';
import 'package:auth/src/auth/auth_status_notifier.dart';
import 'package:core/core.dart';
import 'package:auth/src/data/models/permission_model.dart';
import 'package:auth/src/data/models/profiles/auth_profile_model.dart';
import 'package:auth/src/data/models/responses/auth_account_settings_response_dto.dart';
import 'package:auth/src/data/models/user_model.dart';
import 'package:auth/src/domain/entities/auth_account_settings_entity.dart';
import 'package:auth/src/domain/entities/auth_identity_entity.dart';
import 'package:auth/src/domain/entities/auth_profile_entity.dart';
import 'package:auth/src/domain/entities/auth_response_entity.dart';
import 'package:auth/src/domain/entities/permission_entity.dart';
import 'package:auth/src/domain/entities/user_entity.dart';
import 'package:auth/src/domain/enums/auth_session_status.dart';
import 'package:auth/src/domain/enums/user_type.dart';
import 'package:auth/src/session/session_cache.dart';
import 'package:auth/src/session/session_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:network/network.dart';

/// The application's single source of truth for authenticated user state.
///
/// Owns the full [AuthSessionEntity] — tokens, user, profile, account
/// settings, permissions, verification flags — and drives
/// [AuthStatusNotifier] so the routers redirect correctly. Every feature
/// that needs identity data ([session.user.email], [session.userType],
/// [session.permissions], etc.) reads it from here instead of duplicating
/// caches or re-hitting the API.
///
/// [current] composes the live tokens from [TokenManager] on every read, so
/// consumers observe the freshest token even after a silent refresh by the
/// [AuthInterceptor] — no callback plumbing required in the common case.
class SessionManager {
  SessionManager({
    required SessionRepository repository,
    required SessionCache cache,
    required TokenManager tokenManager,
    required AuthStatusNotifier authStatusNotifier,
  }) : _repository = repository,
       _cache = cache,
       _tokenManager = tokenManager,
       _authStatusNotifier = authStatusNotifier;

  final SessionRepository _repository;
  final SessionCache _cache;
  final TokenManager _tokenManager;
  final AuthStatusNotifier _authStatusNotifier;

  // ── Reactive handle ──────────────────────────────────────────────────────

  /// Observable session — widgets bind to this and rebuild when the session
  /// changes. Emits `null` when signed out.
  ///
  /// Note: this notifier is fed straight from [SessionCache], so it does NOT
  /// re-fire when only the tokens rotate (refresh happens against
  /// [TokenManager], not the cache). Callers that care about token identity
  /// should read [current] on-demand — every access re-composes live tokens.
  ValueListenable<AuthSessionEntity?> watch() => _cache.listenable;

  // ── Core API ─────────────────────────────────────────────────────────────

  /// Returns the current session, or `null` if signed out. Tokens are
  /// composed live from [TokenManager] so they reflect the latest silent
  /// refresh even if the cached snapshot predates it.
  AuthSessionEntity? current() {
    final cached = _cache.value;
    if (cached == null) return null;
    final liveAccess = _tokenManager.accessToken;
    final liveRefresh = _tokenManager.refreshToken;
    if (liveAccess == null ||
        liveAccess.isEmpty ||
        liveRefresh == null ||
        liveRefresh.isEmpty) {
      // Tokens were cleared out from underneath us (e.g. a race with
      // onUnauthorized). Treat as signed out.
      return null;
    }
    if (liveAccess == cached.accessToken &&
        liveRefresh == cached.refreshToken) {
      return cached;
    }
    return cached.copyWith(
      accessToken: liveAccess,
      refreshToken: liveRefresh,
    );
  }

  /// Persist a brand-new session and flip the notifier to authenticated.
  /// Called from every login write path (OTP verify, Google sign-in,
  /// registration completion).
  Future<void> save(AuthSessionEntity session) async {
    await _repository.save(session);
    _authStatusNotifier.update(
      AuthStatus.authenticated,
      isProfileCompleted: session.isProfileCreated,
    );
  }

  /// Apply a partial mutation to the current session (change-email,
  /// change-phone, change-language, profile edits, etc.). No-ops when there
  /// is no active session. Returns the new session, or `null` if no-op.
  Future<AuthSessionEntity?> update(
    AuthSessionEntity Function(AuthSessionEntity current) builder,
  ) => _repository.update(builder);

  /// Rehydrate the session from Hive at startup. Idempotent — safe to call
  /// more than once. Flips the notifier to authenticated on success so the
  /// splash screen redirects into the app; leaves it unchanged on `null`
  /// (splash then dispatches its normal unauthenticated flow).
  Future<AuthSessionEntity?> restore() async {
    final restored = await _repository.restore();
    if (restored != null) {
      _authStatusNotifier.update(
        AuthStatus.authenticated,
        isProfileCompleted: restored.isProfileCreated,
      );
    }
    return restored;
  }

  /// Wipe every session tier and flip the notifier to unauthenticated.
  /// Used by logout, delete-account, and the 401-refresh-failure handler.
  Future<void> clear() async {
    await _repository.clear();
    _authStatusNotifier.update(AuthStatus.unauthenticated);
  }

  // ── Login-verify / GET-me composition ────────────────────────────────────
  //
  // `LoginResponseDto` (`auth/login/verify`, `auth/social/login`) carries
  // only tokens + status — no user/profile payload — so an ACTIVE result
  // cannot be turned into a full [AuthSessionEntity] on its own. The caller
  // (AuthBloc / EmailOtpPage) primes the tokens first so a follow-up
  // `GET /me` call is authenticated, then hands the fetched [AuthIdentity]
  // to [saveFromIdentity] to persist the composed session in one step.

  /// Writes [accessToken]/[refreshToken] straight to the token layer without
  /// touching the session snapshot. Narrow, single-purpose: authenticates
  /// the `GET /me` call that must follow an ACTIVE login/verify before a full
  /// session exists. If that call fails, the Hive/cache tiers are untouched
  /// here, so [current] still reports signed-out.
  Future<void> primeTokens({
    required String accessToken,
    required String refreshToken,
  }) => _tokenManager.saveTokens(
    accessToken: accessToken,
    refreshToken: refreshToken,
  );

  /// Builds and persists a full session from bare tokens plus a freshly
  /// fetched [identity] (see the login-verify/GET-me composition note above).
  Future<void> saveFromIdentity({
    required String accessToken,
    required String refreshToken,
    required AuthIdentity identity,
  }) => save(
    AuthSessionEntity(
      accessToken: accessToken,
      refreshToken: refreshToken,
      status: AuthSessionStatus.authenticated,
      isEmailVerified: true,
      isProfileCreated: true,
      user: UserModel(
        id: identity.id,
        email: identity.email,
        isVerified: true,
        isActive: true,
        type: identity.userType,
      ),
      permissions: identity.permissions
          .map((name) => PermissionModel(name: name))
          .toList(),
      permissionsSyncedAt: DateTime.now(),
    ),
  );

  /// Overwrites the current session's identity fields (`user.type`,
  /// `permissions`) from a freshly fetched [identity] — used on resume
  /// (after [restore]) per the "GET /me re-hydration" decision, so a stale
  /// persisted snapshot (e.g. a role/permission change since last launch, or
  /// the retired `companyProvider` value) self-heals. No-op when signed out.
  Future<AuthSessionEntity?> hydrateIdentity(AuthIdentity identity) {
    final existing = current();
    if (existing == null) return Future.value();
    final updatedUser = UserModel(
      id: existing.user.id,
      email: identity.email,
      isVerified: existing.user.isVerified,
      isActive: existing.user.isActive,
      type: identity.userType,
    );
    return update(
      (s) => s.copyWith(
        user: updatedUser,
        permissions: identity.permissions
            .map((name) => PermissionModel(name: name))
            .toList(),
        permissionsSyncedAt: DateTime.now(),
      ),
    );
  }

  // ── Guard helpers ────────────────────────────────────────────────────────

  /// `true` when a session is present and its tokens are live.
  bool get isAuthenticated => current() != null;

  /// Whether the account has completed email verification.
  bool get isEmailVerified => current()?.isEmailVerified ?? false;

  /// Whether the profile has been created (used for onboarding gates).
  bool get isProfileCompleted => current()?.isProfileCreated ?? false;

  /// The signed-in account's [UserType], or `null` when signed out.
  UserType? get userType => current()?.user.type;

  /// Whether the signed-in account matches [type].
  bool isUserType(UserType type) => userType == type;

  /// `true` for both [UserType.individualProvider] and
  /// [UserType.organizationProvider] — the two variants sharing the
  /// `BusinessProviderAuthProfileResponseDto` profile shape.
  bool get isProvider =>
      userType == UserType.individualProvider ||
      userType == UserType.organizationProvider;

  /// `true` for [UserType.organizationProvider] specifically.
  bool get isCompany => userType == UserType.organizationProvider;

  /// `true` for [UserType.client].
  bool get isClient => userType == UserType.client;

  /// `true` for [UserType.worker].
  bool get isWorker => userType == UserType.worker;

  /// The embedded account settings snapshot (provider-owner accounts only).
  AuthAccountSettingsEntity? get accountSettings => current()?.accountSettings;

  /// The embedded profile (client / worker / business-provider variant),
  /// or `null` when the session has no profile payload yet.
  AuthProfileEntity? get profile => current()?.profile;

  /// Permissions granted to the current session.
  List<PermissionEntity> get permissions => current()?.permissions ?? const [];

  /// The signed-in [UserEntity], or `null` when signed out.
  UserEntity? get user => current()?.user;

  // ── Derived display getters ─────────────────────────────────────────────
  //
  // These abstract over the profile `oneOf` variant so UI never needs to
  // know whether the signed-in account is a client, worker, or provider.

  /// A personal display name for the signed-in account.
  ///
  /// Prefers the account-settings owner name (set for provider owners),
  /// then falls back to the profile's own name field for clients/workers.
  /// `null` when nothing is available yet (e.g. a session with no profile).
  String? get displayName {
    final settingsName = accountSettings?.name;
    if (settingsName != null && settingsName.trim().isNotEmpty) {
      return settingsName;
    }
    return switch (profile) {
      ClientProfileModel(:final fullName) => fullName,
      WorkerProfileModel(:final name) => name,
      _ => null,
    };
  }

  /// The business/company name — `null` unless the signed-in account is a
  /// provider ([isProvider]) with a business name on file.
  String? get businessName {
    final p = profile;
    return p is BusinessProviderProfileModel ? p.businessName : null;
  }

  /// The best available email: account-settings email (provider owners) or
  /// the login user's email.
  String? get email => accountSettings?.email ?? user?.email;

  /// The best available phone number: account-settings phone (provider
  /// owners, only after verification) or the worker profile's phone.
  String? get phone {
    final settingsPhone = accountSettings?.phone;
    if (settingsPhone != null && settingsPhone.isNotEmpty) {
      return settingsPhone;
    }
    final p = profile;
    return p is WorkerProfileModel ? p.phoneNumber : null;
  }

  /// Up to two initials derived from [displayName], [businessName], or
  /// [email], in that order — a stable placeholder for avatar UI.
  String? get initials => initialsOf(displayName ?? businessName ?? email);

  /// Avatar image URL. No such field exists in the current backend
  /// contract (session, profile, or account settings) — kept as a stable
  /// seam for when one is added. Always `null` today.
  String? get avatar => null;

  // ── Mutation helpers ─────────────────────────────────────────────────────
  //
  // Convenience single-field updates over `update()`, for call sites that
  // change exactly one thing after it has already been persisted server-side
  // (e.g. the contact-verification flow, a language picker). Multi-field
  // saves (e.g. a PATCH that changes name + language together) should still
  // call `update()` directly to stay atomic — see AccountSettingsBloc.

  /// Updates the account-settings email in-place. No-op (returns `null`) if
  /// the session has no account-settings snapshot (clients/workers).
  Future<AuthSessionEntity?> setEmail(String email) =>
      _updateAccountSettings((s) => s.copyWith(email: email));

  /// Updates the account-settings phone in-place. Pass `null` to clear it.
  Future<AuthSessionEntity?> setPhone(String? phone) =>
      _updateAccountSettings((s) => s.copyWith(phone: phone));

  /// Updates the account-settings preferred language (`"ar"` or `"en"`)
  /// in-place.
  Future<AuthSessionEntity?> setLanguage(String preferredLanguage) =>
      _updateAccountSettings(
        (s) => s.copyWith(preferredLanguage: preferredLanguage),
      );

  /// Replaces the embedded profile in-place (e.g. after a future
  /// business-profile edit feature).
  Future<AuthSessionEntity?> setProfile(AuthProfileModel profile) =>
      update((s) => s.copyWith(profile: profile));

  /// Replaces the granted permissions in-place (e.g. after a role change is
  /// pushed by the backend).
  Future<AuthSessionEntity?> setPermissions(
    List<PermissionModel> permissions,
  ) => update((s) => s.copyWith(permissions: permissions));

  Future<AuthSessionEntity?> _updateAccountSettings(
    AuthAccountSettingsModel Function(AuthAccountSettingsModel current) mutate,
  ) {
    final existing = current()?.accountSettings;
    if (existing is! AuthAccountSettingsModel) return Future.value();
    return update((s) => s.copyWith(accountSettings: mutate(existing)));
  }
}
