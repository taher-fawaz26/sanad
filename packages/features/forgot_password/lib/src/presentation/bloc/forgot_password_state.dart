part of 'forgot_password_bloc.dart';

sealed class ForgotPasswordState extends Equatable {
  const ForgotPasswordState();

  @override
  List<Object?> get props => [];
}

class ForgotPasswordInitialState extends ForgotPasswordState {
  const ForgotPasswordInitialState();
}

class ForgotPasswordRequestLoadingState extends ForgotPasswordState {
  const ForgotPasswordRequestLoadingState();
}

class ForgotPasswordOtpSentState extends ForgotPasswordState {
  const ForgotPasswordOtpSentState();
}

class ForgotPasswordRequestFailureState extends ForgotPasswordState {
  const ForgotPasswordRequestFailureState(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class ForgotPasswordOtpVerifyLoadingState extends ForgotPasswordState {
  const ForgotPasswordOtpVerifyLoadingState();
}

class ForgotPasswordOtpResendLoadingState extends ForgotPasswordState {
  const ForgotPasswordOtpResendLoadingState();
}

class ForgotPasswordOtpReadyState extends ForgotPasswordState {
  const ForgotPasswordOtpReadyState();
}

class ForgotPasswordOtpVerifiedState extends ForgotPasswordState {
  const ForgotPasswordOtpVerifiedState();
}

class ForgotPasswordOtpFailureState extends ForgotPasswordState {
  const ForgotPasswordOtpFailureState(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class ForgotPasswordResetLoadingState extends ForgotPasswordState {
  const ForgotPasswordResetLoadingState();
}

class ForgotPasswordResetSuccessState extends ForgotPasswordState {
  const ForgotPasswordResetSuccessState();
}

class ForgotPasswordResetFailureState extends ForgotPasswordState {
  const ForgotPasswordResetFailureState(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
