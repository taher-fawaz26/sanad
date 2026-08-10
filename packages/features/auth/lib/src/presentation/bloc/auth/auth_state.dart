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

/// OTP dispatched — navigate to the shared OTP screen for [email] under
/// [intent].
class AuthOtpSentState extends AuthState {
  const AuthOtpSentState({required this.email, required this.intent});

  final String email;
  final AuthFlowIntent intent;

  @override
  List<Object?> get props => [email, intent];
}

class AuthOtpRequestFailureState extends AuthState {
  const AuthOtpRequestFailureState(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

// ─── Resend info (server-driven cooldown) ──────────────────────────────────

class AuthResendInfoState extends AuthState {
  const AuthResendInfoState(this.resendInfo);

  final ResendInfo resendInfo;

  @override
  List<Object?> get props => [resendInfo];
}

class AuthResendInfoFailureState extends AuthState {
  const AuthResendInfoFailureState(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

// ─── Post-authentication (reached via OTP verify in `EmailOtpPage`, or
// Google sign-in here) ──────────────────────────────────────────────────────

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

/// Account exists but is suspended (`LoginResponseDto.status: SUSPENDED`) —
/// both tokens are null on the wire, so there is nothing to persist.
class AuthSuspendedState extends AuthState {
  const AuthSuspendedState();
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
