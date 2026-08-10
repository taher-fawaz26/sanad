import 'package:auth/src/domain/entities/login_result_entity.dart';
import 'package:auth/src/domain/enums/auth_account_status.dart';

/// Data model for [LoginResult] — inherits fields, adds JSON I/O.
class LoginResponseModel extends LoginResult {
  const LoginResponseModel({
    required super.status,
    super.accessToken,
    super.refreshToken,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status'];
    if (rawStatus is! String) {
      throw const FormatException(
        'LoginResponseDto.status is required and must be a string.',
      );
    }
    return LoginResponseModel(
      status: AuthAccountStatus.fromString(rawStatus),
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status.value,
    'accessToken': accessToken,
    'refreshToken': refreshToken,
  };
}
