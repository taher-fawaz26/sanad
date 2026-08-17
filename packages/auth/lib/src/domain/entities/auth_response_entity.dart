import 'package:auth/src/domain/entities/auth_account_settings_entity.dart';
import 'package:auth/src/domain/entities/auth_profile_entity.dart';
import 'package:auth/src/domain/entities/permission_entity.dart';
import 'package:auth/src/domain/entities/user_entity.dart';
import 'package:auth/src/domain/enums/auth_session_status.dart';
import 'package:equatable/equatable.dart';

/// Base type for the Swagger `oneOf` auth response payload.
///
/// The API returns either an onboarding hand-off or a full authenticated
/// session. Concrete data models extend [OnboardingAuthEntity] /
/// [AuthSessionEntity] (inheritance, no mapper). Those subclasses are
/// intentionally not `final` so models in `data/` may extend them.
sealed class AuthResponseEntity extends Equatable {
  const AuthResponseEntity();
}

/// Onboarding hand-off (`status: onboarding`) — short-lived token, no session.
class OnboardingAuthEntity extends AuthResponseEntity {
  const OnboardingAuthEntity({
    required this.status,
    required this.onboardingToken,
    required this.isEmailVerified,
    required this.isProfileCreated,
    required this.user,
  });

  final AuthSessionStatus status;
  final String onboardingToken;
  final bool isEmailVerified;
  final bool isProfileCreated;
  final UserEntity user;

  @override
  List<Object?> get props => [
    status,
    onboardingToken,
    isEmailVerified,
    isProfileCreated,
    user,
  ];
}

/// Authenticated session (`status: authenticated`) — tokens + optional profile.
///
/// [profile] is itself a Swagger `oneOf`, resolved via [AuthProfileEntity].
/// Some endpoints (e.g. `auth/profile`) omit `profile` even when
/// [isProfileCreated] is true; callers must tolerate a null [profile].
///
/// [accountSettings] is provider-owner-only per the backend contract — it is
/// always `null` for clients and workers, and may be `null` for providers on
/// endpoints that omit it.
class AuthSessionEntity extends AuthResponseEntity {
  const AuthSessionEntity({
    required this.accessToken,
    required this.refreshToken,
    required this.status,
    required this.isEmailVerified,
    required this.isProfileCreated,
    required this.user,
    required this.permissions,
    this.profile,
    this.accountSettings,
    this.permissionsSyncedAt,
  });

  final String accessToken;
  final String refreshToken;
  final AuthSessionStatus status;
  final bool isEmailVerified;
  final bool isProfileCreated;
  final UserEntity user;
  final AuthProfileEntity? profile;
  final AuthAccountSettingsEntity? accountSettings;
  final List<PermissionEntity> permissions;

  /// When [permissions] was last populated from a `/me`-sourced identity
  /// (login, or the post-splash resync) — `null` if this session was ever
  /// saved by a path that does not call `/me` (e.g. worker-invitation
  /// acceptance), in which case [permissions] may be an empty placeholder
  /// rather than a genuine "this user has nothing" result.
  ///
  /// This is the provenance flag `AuthorizationReader.isResolved` is built
  /// on: an authorization consumer must treat a `null` timestamp as
  /// "unknown", never as a denial. See `packages/authorization`.
  final DateTime? permissionsSyncedAt;

  /// Returns a copy with the given fields replaced.
  ///
  /// Nullable fields ([profile], [accountSettings]) use a sentinel default so
  /// omitting an argument keeps the current value and explicitly passing
  /// `null` clears it — the standard Dart copyWith idiom. Non-nullable
  /// fields simply fall back to their current value when omitted.
  /// [permissionsSyncedAt] is not sentinel-based: every write path either
  /// advances it forward (a fresh `/me` fetch) or intentionally leaves it
  /// untouched — nothing ever needs to explicitly clear it back to `null`.
  AuthSessionEntity copyWith({
    String? accessToken,
    String? refreshToken,
    AuthSessionStatus? status,
    bool? isEmailVerified,
    bool? isProfileCreated,
    UserEntity? user,
    List<PermissionEntity>? permissions,
    DateTime? permissionsSyncedAt,
    Object? profile = _copyWithSentinel,
    Object? accountSettings = _copyWithSentinel,
  }) {
    return AuthSessionEntity(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      status: status ?? this.status,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isProfileCreated: isProfileCreated ?? this.isProfileCreated,
      user: user ?? this.user,
      permissions: permissions ?? this.permissions,
      permissionsSyncedAt: permissionsSyncedAt ?? this.permissionsSyncedAt,
      profile: identical(profile, _copyWithSentinel)
          ? this.profile
          : profile as AuthProfileEntity?,
      accountSettings: identical(accountSettings, _copyWithSentinel)
          ? this.accountSettings
          : accountSettings as AuthAccountSettingsEntity?,
    );
  }

  @override
  List<Object?> get props => [
    accessToken,
    refreshToken,
    status,
    isEmailVerified,
    isProfileCreated,
    user,
    profile,
    accountSettings,
    permissions,
    permissionsSyncedAt,
  ];
}

/// Private sentinel that lets [AuthSessionEntity.copyWith] distinguish
/// "argument omitted" from "argument explicitly set to null".
const Object _copyWithSentinel = Object();
