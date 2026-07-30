import 'package:auth/src/domain/entities/email_auth_result.dart';
import 'package:auth/src/domain/entities/user_entity.dart';
import 'package:auth/src/domain/enums/user_type.dart';

/// Parses the `oneOf` response of `POST /auth/email/verify` into the domain
/// [EmailAuthResult] union.
abstract final class EmailVerifyResponse {
  EmailVerifyResponse._();

  static EmailAuthResult fromJson(Map<String, dynamic> json) {
    final status = (json['status'] as String?)?.toLowerCase();
    final accessToken = json['accessToken'] as String?;
    final user = (json['user'] as Map<String, dynamic>?) ?? const {};

    final isAuthenticated = status == 'authenticated' ||
        (accessToken != null && accessToken.isNotEmpty);

    if (isAuthenticated) {
      return AuthenticatedResult(
        accessToken: accessToken ?? '',
        refreshToken: json['refreshToken'] as String? ?? '',
        user: UserEntity(
          sub: user['id'] as String? ?? '',
          identifier: user['email'] as String? ?? '',
          identifierType: 'email',
          isVerified: user['isVerified'] as bool? ?? false,
          isProfileCompleted: json['isProfileCreated'] as bool? ?? false,
          type: _mapUserType(user['userType'] as String?),
        ),
      );
    }

    return OnboardingResult(
      onboardingToken: json['onboardingToken'] as String? ?? '',
      email: user['email'] as String? ?? '',
      userId: user['id'] as String? ?? '',
    );
  }

  /// Maps the backend `userType` (`client`, `individualProvider`,
  /// `companyProvider`, `worker`, `admin`) onto the app's coarse
  /// [UserType] (`client` vs `provider`).
  static UserType _mapUserType(String? raw) {
    return raw?.toLowerCase() == 'client' ? UserType.client : UserType.provider;
  }
}
