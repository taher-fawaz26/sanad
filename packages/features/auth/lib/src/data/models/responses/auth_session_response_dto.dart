import 'package:auth/src/data/models/auth_profile_factory.dart';
import 'package:auth/src/data/models/permission_model.dart';
import 'package:auth/src/data/models/user_model.dart';
import 'package:auth/src/domain/entities/auth_profile_entity.dart';
import 'package:auth/src/domain/entities/auth_response_entity.dart';
import 'package:auth/src/domain/entities/permission_entity.dart';
import 'package:auth/src/domain/enums/user_type.dart';

/// Data model for [AuthSessionEntity] — inherits fields, adds JSON I/O.
///
/// [AuthSessionEntity.profile] is typed as [AuthProfileEntity]; the concrete
/// model is chosen from `user.type` via [AuthProfileFactory] (Swagger `oneOf`).
class AuthSessionResponseModel extends AuthSessionEntity {
  const AuthSessionResponseModel({
    required super.accessToken,
    required super.refreshToken,
    required super.status,
    required super.isEmailVerified,
    required super.isProfileCreated,
    required super.user,
    required super.profile,
    required super.permissions,
  });

  factory AuthSessionResponseModel.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>;
    final user = UserModel.fromJson(userJson);
    final typeRaw = userJson['userType'] ?? userJson['type'];
    final type = user.type ??
        (typeRaw is String
            ? UserType.fromString(typeRaw)
            : (throw ArgumentError(
                'Auth session user is missing userType/type.',
              )));

    return AuthSessionResponseModel(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      status: json['status'] as String,
      isEmailVerified: json['isEmailVerified'] as bool,
      isProfileCreated: json['isProfileCreated'] as bool,
      user: user,
      profile: AuthProfileFactory.fromJson(
        type: type,
        json: json['profile'] as Map<String, dynamic>,
      ),
      permissions: _parsePermissions(json['permissions'] as List<dynamic>?),
    );
  }

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'status': status,
        'isEmailVerified': isEmailVerified,
        'isProfileCreated': isProfileCreated,
        'user': (user as UserModel).toJson(),
        'profile': AuthProfileFactory.toJson(profile),
        'permissions': permissions
            .cast<PermissionModel>()
            .map((e) => e.toJson())
            .toList(),
      };
}

/// Handles both `["*"]` (plain strings) and `[{name:…}]` (objects).
List<PermissionEntity> _parsePermissions(List<dynamic>? raw) {
  if (raw == null || raw.isEmpty) return const [];
  return raw.map<PermissionEntity>((e) {
    if (e is String) return PermissionModel(name: e);
    return PermissionModel.fromJson(e as Map<String, dynamic>);
  }).toList();
}
