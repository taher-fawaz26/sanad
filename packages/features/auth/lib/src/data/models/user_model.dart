import 'package:auth/src/domain/entities/user_entity.dart';
import 'package:auth/src/domain/enums/user_type.dart';
import 'package:core/core.dart';

class UserModel extends UserEntity implements EntityConverter<UserEntity> {
  const UserModel({
    required super.id,
    required super.email,
    required super.isVerified,
    required super.isActive,
    required super.type,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Live API uses `userType`; older payloads may still send `type`.
    final typeRaw = json['userType'] ?? json['type'];
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      // `auth/profile` may omit this on `user` and only send
      // top-level `isEmailVerified` — session parser fills it before call.
      isVerified: (json['isVerified'] as bool?) ?? false,
      isActive: json['isActive'] as bool?,
      type: typeRaw is String ? UserType.fromString(typeRaw) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'isVerified': isVerified,
    'isActive': isActive,
    'userType': type?.value,
  };

  @override
  UserEntity toEntity() => UserEntity(
    id: id,
    email: email,
    isVerified: isVerified,
    isActive: isActive,
    type: type,
  );
}
