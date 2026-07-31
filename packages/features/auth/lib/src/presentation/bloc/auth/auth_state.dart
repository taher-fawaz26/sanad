part of 'auth_bloc.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => const [];
}

class AuthInitialState extends AuthState {
  const AuthInitialState();
}

// ─── Request OTP ────────────────────────────────────────────────────────────

class AuthOtpRequestLoadingState extends AuthState {
  const AuthOtpRequestLoadingState();
}

/// OTP dispatched — navigate to the shared OTP screen for [email].
class AuthOtpSentState extends AuthState {
  const AuthOtpSentState(this.email);

  final String email;

  @override
  List<Object?> get props => [email];
}

class AuthOtpRequestFailureState extends AuthState {
  const AuthOtpRequestFailureState(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

// ─── Verify OTP ─────────────────────────────────────────────────────────────

class AuthOtpVerifyLoadingState extends AuthState {
  const AuthOtpVerifyLoadingState();
}

/// Existing user — session started, navigate to the dashboard.
class AuthAuthenticatedState extends AuthState {
  const AuthAuthenticatedState(this.user);

  final UserEntity user;

  @override
  List<Object?> get props => [user];
}

/// New user — must complete onboarding; carries the email + onboarding token.
class AuthOnboardingRequiredState extends AuthState {
  const AuthOnboardingRequiredState({
    required this.email,
    required this.onboardingToken,
  });

  final String email;
  final String onboardingToken;

  @override
  List<Object?> get props => [email, onboardingToken];
}

class AuthOtpVerifyFailureState extends AuthState {
  const AuthOtpVerifyFailureState(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

// ─── Logout ─────────────────────────────────────────────────────────────────

class AuthLogoutLoadingState extends AuthState {
  const AuthLogoutLoadingState();
}

class AuthLogoutSuccessState extends AuthState {
  const AuthLogoutSuccessState(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class AuthLogoutFailureState extends AuthState {
  const AuthLogoutFailureState(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

// ─── Delete account ───────────────────────────────────────────────────────

class AuthDeleteAccountLoadingState extends AuthState {
  const AuthDeleteAccountLoadingState(this.user);

  final UserEntity user;

  @override
  List<Object?> get props => [user];
}

class AuthDeleteAccountFailureState extends AuthState {
  const AuthDeleteAccountFailureState(this.failure, {required this.user});

  final Failure failure;
  final UserEntity? user;

  @override
  List<Object?> get props => [failure, user];
}

// ─── Google Sign-In ──────────────────────────────────────────────────────────

class AuthGoogleSignInLoadingState extends AuthState {
  const AuthGoogleSignInLoadingState();
}

class AuthGoogleSignInFailureState extends AuthState {
  const AuthGoogleSignInFailureState(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

// ─── Session check (splash) ─────────────────────────────────────────────────

class AuthCheckSignInStatusLoadingState extends AuthState {
  const AuthCheckSignInStatusLoadingState();
}

class AuthCheckSignInStatusSuccessState extends AuthState {
  const AuthCheckSignInStatusSuccessState(this.user);

  final UserEntity user;

  @override
  List<Object?> get props => [user];
}

class AuthCheckSignInStatusFailureState extends AuthState {
  const AuthCheckSignInStatusFailureState(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
