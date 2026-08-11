import 'package:auth/src/data/models/responses/auth_session_response_dto.dart';
import 'package:auth/src/data/models/responses/onboarding_auth_response_dto.dart';
import 'package:auth/src/domain/entities/auth_response_entity.dart';
import 'package:auth/src/domain/enums/auth_session_status.dart';

/// Parses the Swagger `oneOf` auth response (onboarding | session).
///
/// Discriminator: the `status` field, per the Swagger contract — both DTOs
/// share the same two-value enum (`onboarding` | `authenticated`).
abstract final class AuthResponseModel {
  AuthResponseModel._();

  static AuthResponseEntity fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status'];
    if (rawStatus is! String) {
      throw const FormatException(
        'Auth response is missing a "status" field.',
      );
    }
    return switch (AuthSessionStatus.fromString(rawStatus)) {
      AuthSessionStatus.onboarding => OnboardingAuthResponseModel.fromJson(
        json,
      ),
      AuthSessionStatus.authenticated => AuthSessionResponseModel.fromJson(
        json,
      ),
    };
  }
}
