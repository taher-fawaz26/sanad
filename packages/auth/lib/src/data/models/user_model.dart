import 'package:auth/src/domain/entities/user_entity.dart';
import 'package:auth/src/domain/enums/user_type.dart';
import 'package:core/core.dart';

class UserModel extends UserEntity implements EntityConverter<UserEntity> {
  const UserModel({
    required super.sub,
    required super.identifier,
    required super.identifierType,
    required super.isVerified,
    required super.isProfileCompleted,
    required super.type,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        sub: json['sub'] as String,
        identifier: json['identifier'] as String,
        identifierType: json['identifierType'] as String,
        isVerified: json['isVerified'] as bool,
        isProfileCompleted: json['isProfileCompleted'] as bool,
        type: UserType.fromString(json['type'] as String),
      );

  /// Constructs a [UserModel] from a decoded JWT payload.
  ///
  /// Used when restoring a session from a stored access token.
  factory UserModel.fromToken(Map<String, dynamic> json) =>
      UserModel.fromJson(json);

  @override
  UserEntity toEntity() => UserEntity(
        sub: sub,
        identifier: identifier,
        identifierType: identifierType,
        isVerified: isVerified,
        isProfileCompleted: isProfileCompleted,
        type: type,
      );
}
