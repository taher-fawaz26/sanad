import 'package:equatable/equatable.dart';
import 'package:otp/src/domain/enums/otp_purpose.dart';

class ValidateOtpParams extends Equatable {
  const ValidateOtpParams({
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

class ResendOtpParams extends Equatable {
  const ResendOtpParams({
    required this.identifier,
    required this.purpose,
  });

  final String identifier;
  final OtpPurpose purpose;

  @override
  List<Object?> get props => [identifier, purpose];
}
