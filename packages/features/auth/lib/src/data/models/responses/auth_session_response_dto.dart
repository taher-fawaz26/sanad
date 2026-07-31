import 'package:auth/src/data/models/auth_profile_factory.dart';
import 'package:auth/src/data/models/permission_model.dart';
import 'package:auth/src/data/models/user_model.dart';
import 'package:auth/src/domain/entities/auth_profile_entity.dart';
import 'package:auth/src/domain/enums/user_type.dart';

/// Authenticated session payload (`status: authenticated`).
///
/// [profile] is typed as [AuthProfileEntity]; the concrete model is chosen
/// from `user.type` via [AuthProfileFactory] (Swagger `oneOf`).
class AuthSessionResponseModel {
  const AuthSessionResponseModel({
    required this.accessToken,
    required this.refreshToken,
    required this.status,
    required this.isEmailVerified,
    required this.isProfileCreated,
    required this.user,
    required this.profile,
    required this.permissions,
  });

  factory AuthSessionResponseModel.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>;
    final user = UserModel.fromJson(userJson);
    final type = user.type ?? UserType.fromString(userJson['type'] as String);

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
      permissions: (json['permissions'] as List<dynamic>? ?? const [])
          .map((e) => PermissionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String accessToken;
  final String refreshToken;
  final String status;
  final bool isEmailVerified;
  final bool isProfileCreated;
  final UserModel user;
  final AuthProfileEntity profile;
  final List<PermissionModel> permissions;

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'status': status,
    'isEmailVerified': isEmailVerified,
    'isProfileCreated': isProfileCreated,
    'user': user.toJson(),
    'profile': AuthProfileFactory.toJson(profile),
    'permissions': permissions.map((e) => e.toJson()).toList(),
  };
}
