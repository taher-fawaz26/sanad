import 'package:auth/src/domain/entities/user_entity.dart';
import 'package:equatable/equatable.dart';

/// Outcome of `POST /auth/email/verify`.
///
/// The backend returns one of two shapes discriminated by `status`:
/// * [AuthenticatedResult] (`status: authenticated`) — the account already
///   exists and is fully provisioned; the response carries session tokens.
/// * [OnboardingResult] (`status: onboarding`) — a new (or profile-incomplete)
///   account that must complete the registration flow; the response carries a
///   short-lived onboarding token instead of session tokens.
sealed class EmailAuthResult extends Equatable {
  const EmailAuthResult();
}

/// Existing user — sign-in complete, session tokens issued.
class AuthenticatedResult extends EmailAuthResult {
  const AuthenticatedResult({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final UserEntity user;

  @override
  List<Object?> get props => [accessToken, refreshToken, user];
}

/// New user — must continue the registration/onboarding flow.
class OnboardingResult extends EmailAuthResult {
  const OnboardingResult({
    required this.onboardingToken,
    required this.email,
    required this.userId,
  });

  final String onboardingToken;
  final String email;
  final String userId;

  @override
  List<Object?> get props => [onboardingToken, email, userId];
}
