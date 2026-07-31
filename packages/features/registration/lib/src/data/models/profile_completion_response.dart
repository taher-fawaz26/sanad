import 'package:auth/src/domain/entities/email_auth_result.dart';
import 'package:auth/src/domain/entities/user_entity.dart';
import 'package:auth/src/domain/enums/user_type.dart';

/// Parses the profile completion response into [AuthenticatedResult].
///
/// Profile creation endpoints return the same shape as email verification
/// when successful — an authenticated session with tokens.
abstract final class ProfileCompletionResponse {
  ProfileCompletionResponse._();

  static AuthenticatedResult fromJson(Map<String, dynamic> json) {
    final user = (json['user'] as Map<String, dynamic>?) ?? const {};

    return AuthenticatedResult(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      user: UserEntity(
        sub: user['id'] as String? ?? '',
        identifier: user['email'] as String? ?? '',
        identifierType: 'email',
        isVerified: user['isVerified'] as bool? ?? false,
        isProfileCompleted: json['isProfileCreated'] as bool? ?? true,
        type: _mapUserType(user['userType'] as String?),
      ),
    );
  }

  static UserType _mapUserType(String? raw) {
    return raw?.toLowerCase() == 'client' ? UserType.client : UserType.provider;
  }
}
