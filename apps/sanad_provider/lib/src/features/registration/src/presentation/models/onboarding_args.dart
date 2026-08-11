import 'package:equatable/equatable.dart';

/// GoRouter `extra` handed to the registration flow after a new user verifies
/// their email OTP. Carries the verified email and the short-lived onboarding
/// token the backend issued for the profile-creation calls.
class OnboardingArgs extends Equatable {
  const OnboardingArgs({required this.email, required this.onboardingToken});

  final String email;
  final String onboardingToken;

  @override
  List<Object?> get props => [email, onboardingToken];
}
