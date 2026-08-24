part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Request an OTP for [email] under the given [intent] — sign-in and
/// create-account hit different backend endpoints (`auth/login` vs
/// `auth/signup`), so the caller must say which up front.
class AuthRequestOtpEvent extends AuthEvent {
  const AuthRequestOtpEvent({required this.email, required this.intent});

  final String email;
  final AuthFlowIntent intent;

  @override
  List<Object?> get props => [email, intent];
}

/// Resend the active OTP for [email] (single endpoint regardless of intent).
class AuthResendOtpEvent extends AuthEvent {
  const AuthResendOtpEvent(this.email);

  final String email;

  @override
  List<Object?> get props => [email];
}

/// Fetch the server-driven resend cooldown for [email].
class AuthResendInfoRequestedEvent extends AuthEvent {
  const AuthResendInfoRequestedEvent(this.email);

  final String email;

  @override
  List<Object?> get props => [email];
}

class AuthLogoutEvent extends AuthEvent {}

class AuthCheckSignInStatusEvent extends AuthEvent {}

/// Google sign-in under the given [intent].
class AuthGoogleSignInEvent extends AuthEvent {
  const AuthGoogleSignInEvent(this.intent);

  final AuthFlowIntent intent;

  @override
  List<Object?> get props => [intent];
}
