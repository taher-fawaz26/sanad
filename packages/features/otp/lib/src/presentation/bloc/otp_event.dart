part of 'otp_bloc.dart';

sealed class OtpEvent extends Equatable {
  const OtpEvent();

  @override
  List<Object?> get props => [];
}

class OtpValidateEvent extends OtpEvent {
  const OtpValidateEvent({
    required this.identifier,
    required this.otp,
    this.purpose = OtpPurpose.register,
  });

  final String identifier;
  final int otp;
  final OtpPurpose purpose;

  @override
  List<Object?> get props => [identifier, otp, purpose];
}

class OtpResendEvent extends OtpEvent {
  const OtpResendEvent({
    required this.identifier,
    required this.purpose,
  });

  final String identifier;
  final OtpPurpose purpose;

  @override
  List<Object?> get props => [identifier, purpose];
}
