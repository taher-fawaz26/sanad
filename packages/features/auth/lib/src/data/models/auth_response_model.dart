import 'package:auth/src/data/models/responses/auth_session_response_dto.dart';
import 'package:auth/src/data/models/responses/onboarding_auth_response_dto.dart';
import 'package:auth/src/domain/entities/auth_response_entity.dart';

/// Parses the Swagger `oneOf` auth response (onboarding | session).
///
/// Discriminator: presence of `accessToken` (session-only field).
abstract final class AuthResponseModel {
  AuthResponseModel._();

  static AuthResponseEntity fromJson(Map<String, dynamic> json) {
    if (json.containsKey('accessToken')) {
      return AuthSessionResponseModel.fromJson(json);
    }
    return OnboardingAuthResponseModel.fromJson(json);
  }
}
