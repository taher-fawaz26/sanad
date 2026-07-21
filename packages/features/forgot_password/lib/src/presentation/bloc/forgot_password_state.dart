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
  const ForgotPasswordRequestFailureState(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
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
  const ForgotPasswordOtpFailureState(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

class ForgotPasswordResetLoadingState extends ForgotPasswordState {
  const ForgotPasswordResetLoadingState();
}

class ForgotPasswordResetSuccessState extends ForgotPasswordState {
  const ForgotPasswordResetSuccessState();
}

class ForgotPasswordResetFailureState extends ForgotPasswordState {
  const ForgotPasswordResetFailureState(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
