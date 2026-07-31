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
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      isVerified: json['isVerified'] as bool,
      isActive: json['isActive'] as bool?,
      type: json['type'] is String
          ? UserType.fromString(json['type'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'isVerified': isVerified,
    'isActive': isActive,
    'type': type?.value,
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
