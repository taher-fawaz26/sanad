import 'package:auth/src/domain/entities/auth_profile_entity.dart';
import 'package:auth/src/domain/entities/permission_entity.dart';
import 'package:auth/src/domain/entities/user_entity.dart';
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

  final String status;
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
/// Some endpoints (e.g. `auth/email/verify`) omit `profile` even when
/// [isProfileCreated] is true; callers must tolerate a null [profile].
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
  });

  final String accessToken;
  final String refreshToken;
  final String status;
  final bool isEmailVerified;
  final bool isProfileCreated;
  final UserEntity user;
  final AuthProfileEntity? profile;
  final List<PermissionEntity> permissions;

  @override
  List<Object?> get props => [
        accessToken,
        refreshToken,
        status,
        isEmailVerified,
        isProfileCreated,
        user,
        profile,
        permissions,
      ];
}
