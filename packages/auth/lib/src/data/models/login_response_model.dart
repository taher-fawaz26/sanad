import 'package:auth/src/data/models/user_model.dart';
import 'package:auth/src/domain/entities/login_response_entity.dart';
import 'package:core/core.dart';

class LoginResponseModel extends LoginResponseEntity
    implements EntityConverter<LoginResponseEntity> {
  const LoginResponseModel({
    required super.accessToken,
    required super.refreshToken,
    required super.user,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) =>
      LoginResponseModel(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      );

  @override
  LoginResponseEntity toEntity() => LoginResponseEntity(
        accessToken: accessToken,
        refreshToken: refreshToken,
        user: (user as UserModel).toEntity(),
      );
}
