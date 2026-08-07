import 'package:auth/src/data/models/permission_model.dart';
import 'package:auth/src/data/models/profiles/auth_profile_model.dart';
import 'package:auth/src/data/models/responses/auth_account_settings_response_dto.dart';
import 'package:auth/src/data/models/user_model.dart';
import 'package:auth/src/domain/entities/auth_response_entity.dart';
import 'package:auth/src/domain/entities/permission_entity.dart';
import 'package:auth/src/domain/enums/auth_session_status.dart';
import 'package:auth/src/domain/enums/user_type.dart';

/// Data model for [AuthSessionEntity] — inherits fields, adds JSON I/O.
///
/// `AuthSessionEntity.profile` is typed as `AuthProfileEntity`; the concrete
/// model is chosen from `user.userType` via [AuthProfileModel.fromJson]
/// (Swagger `oneOf`).
class AuthSessionResponseModel extends AuthSessionEntity {
  const AuthSessionResponseModel({
    required super.accessToken,
    required super.refreshToken,
    required super.status,
    required super.isEmailVerified,
    required super.isProfileCreated,
    required super.user,
    required super.permissions,
    super.profile,
    super.accountSettings,
  });

  factory AuthSessionResponseModel.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];
    if (rawUser is! Map) {
      throw const FormatException(
        'AuthSessionResponseDto.user is required and must be an object.',
      );
    }
    // Live verify payload may omit `user.isVerified` and only send top-level
    // `isEmailVerified` — copy it onto the user map before parsing.
    final userJson = Map<String, dynamic>.from(rawUser)
      ..putIfAbsent(
        'isVerified',
        () => json['isEmailVerified'] as bool? ?? false,
      );
    final user = UserModel.fromJson(userJson);
    final typeRaw = userJson['userType'] ?? userJson['type'];
    final type =
        user.type ??
        (typeRaw is String
            ? UserType.fromString(typeRaw)
            : (throw const FormatException(
                'AuthSessionResponseDto.user.userType is required.',
              )));

    final rawProfile = json['profile'];
    final profile = rawProfile is Map
        ? AuthProfileModel.fromJson(
            userType: type,
            json: Map<String, dynamic>.from(rawProfile),
          )
        : null;

    final rawAccountSettings = json['accountSettings'];
    final accountSettings = rawAccountSettings is Map
        ? AuthAccountSettingsModel.fromJson(
            Map<String, dynamic>.from(rawAccountSettings),
          )
        : null;

    final rawStatus = json['status'];
    if (rawStatus is! String) {
      throw const FormatException(
        'AuthSessionResponseDto.status is required and must be a string.',
      );
    }

    return AuthSessionResponseModel(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      status: AuthSessionStatus.fromString(rawStatus),
      isEmailVerified: json['isEmailVerified'] as bool,
      isProfileCreated: json['isProfileCreated'] as bool,
      user: user,
      profile: profile,
      accountSettings: accountSettings,
      permissions: _parsePermissions(json['permissions']),
    );
  }

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'status': status.value,
    'isEmailVerified': isEmailVerified,
    'isProfileCreated': isProfileCreated,
    'user': (user as UserModel).toJson(),
    if (profile != null) 'profile': (profile! as AuthProfileModel).toJson(),
    if (accountSettings != null)
      'accountSettings': (accountSettings! as AuthAccountSettingsModel)
          .toJson(),
    'permissions': permissions
        .cast<PermissionModel>()
        .map((e) => e.toJson())
        .toList(),
  };
}

/// Parses the `permissions` array. Absent defaults to empty; a
/// present-but-wrong-shaped value throws rather than being silently dropped.
/// Handles both `["*"]` (plain strings) and `[{name: ...}]` (objects).
List<PermissionEntity> _parsePermissions(dynamic raw) {
  if (raw == null) return const [];
  if (raw is! List) {
    throw FormatException(
      'AuthSessionResponseDto.permissions must be an array, got $raw.',
    );
  }
  return raw.map<PermissionEntity>((e) {
    if (e is String) return PermissionModel(name: e);
    if (e is Map) {
      return PermissionModel.fromJson(Map<String, dynamic>.from(e));
    }
    throw FormatException(
      'AuthSessionResponseDto.permissions entry has unsupported shape: $e',
    );
  }).toList();
}
