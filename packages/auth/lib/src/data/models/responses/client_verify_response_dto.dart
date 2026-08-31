import 'package:auth/src/domain/entities/client_auth_user_entity.dart';
import 'package:auth/src/domain/entities/client_verify_result_entity.dart';
import 'package:auth/src/domain/enums/auth_account_status.dart';

/// Data model for [ClientAuthUser] — inherits fields, adds JSON parsing.
///
/// `email`/`phone` are genuinely nullable (phone-only vs email-only clients);
/// `name` is nullable until profile setup completes. `preferredLanguage`
/// defaults to `"en"` rather than throwing if the backend omits it.
class ClientAuthUserModel extends ClientAuthUser {
  const ClientAuthUserModel({
    required super.id,
    required super.preferredLanguage,
    super.name,
    super.email,
    super.phone,
  });

  factory ClientAuthUserModel.fromJson(Map<String, dynamic> json) =>
      ClientAuthUserModel(
        id: json['id'] as String,
        name: json['name'] as String?,
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        preferredLanguage: json['preferredLanguage'] as String? ?? 'en',
      );
}

/// Data model for [ClientVerifyResult] — inherits fields, adds JSON parsing.
///
/// Tokens are optional on the wire (null unless `status == ACTIVE`); `user` is
/// present only when a session was issued. Parsing never assumes tokens exist.
class ClientVerifyResponseModel extends ClientVerifyResult {
  const ClientVerifyResponseModel({
    required super.status,
    super.accessToken,
    super.refreshToken,
    super.user,
  });

  factory ClientVerifyResponseModel.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status'];
    if (rawStatus is! String) {
      throw const FormatException(
        'ClientVerifyResponseDto.status is required and must be a string.',
      );
    }
    final rawUser = json['user'];
    return ClientVerifyResponseModel(
      status: AuthAccountStatus.fromString(rawStatus),
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      user: rawUser is Map<String, dynamic>
          ? ClientAuthUserModel.fromJson(rawUser)
          : null,
    );
  }
}
