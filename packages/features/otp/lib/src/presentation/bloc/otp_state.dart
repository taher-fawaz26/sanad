part of 'otp_bloc.dart';

sealed class OtpState extends Equatable {
  const OtpState();

  @override
  List<Object?> get props => [];
}

class OtpInitialState extends OtpState {
  const OtpInitialState();
}

class OtpValidateLoadingState extends OtpState {
  const OtpValidateLoadingState();
}

class OtpValidateSuccessState extends OtpState {
  const OtpValidateSuccessState(this.user, this.message);

  final UserEntity user;
  final String message;

  @override
  List<Object?> get props => [user, message];
}

class OtpValidateFailureState extends OtpState {
  const OtpValidateFailureState(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class OtpResendLoadingState extends OtpState {
  const OtpResendLoadingState();
}

class OtpResendSuccessState extends OtpState {
  const OtpResendSuccessState();
}

class OtpResendFailureState extends OtpState {
  const OtpResendFailureState(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
