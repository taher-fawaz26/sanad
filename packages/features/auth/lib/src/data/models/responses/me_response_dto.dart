import 'package:auth/src/domain/entities/auth_identity_entity.dart';
import 'package:auth/src/domain/enums/user_type.dart';

/// Data model for [AuthIdentity] — inherits fields, adds JSON I/O.
class MeResponseModel extends AuthIdentity {
  const MeResponseModel({
    required super.id,
    required super.email,
    required super.userType,
    required super.permissions,
    super.name,
  });

  factory MeResponseModel.fromJson(Map<String, dynamic> json) {
    final rawUserType = json['userType'];
    if (rawUserType is! String) {
      throw const FormatException(
        'MeResponseDto.userType is required and must be a string.',
      );
    }
    return MeResponseModel(
      id: json['id'] as String,
      name: json['name'] as String?,
      email: json['email'] as String,
      userType: UserType.fromString(rawUserType),
      permissions: _parsePermissions(json['permissions']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'userType': userType.value,
    'permissions': permissions,
  };

  static List<String> _parsePermissions(dynamic raw) {
    if (raw == null) return const [];
    if (raw is! List) {
      throw FormatException(
        'MeResponseDto.permissions must be an array, got $raw.',
      );
    }
    return raw.map((e) => e.toString()).toList();
  }
}
