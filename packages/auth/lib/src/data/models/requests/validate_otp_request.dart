import 'package:auth/src/data/models/auth_otp_purpose.dart';
import 'package:equatable/equatable.dart';

class ValidateOtpRequest extends Equatable {
  const ValidateOtpRequest({
    required this.identifier,
    required this.otp,
    this.purpose = AuthOtpPurpose.register,
  });

  final String identifier;
  final int otp;
  final AuthOtpPurpose purpose;

  Map<String, dynamic> toMap() => {
        'identifier': identifier,
        'otp': otp,
        'purpose': purpose.wireValue,
      };

  @override
  List<Object?> get props => [identifier, otp, purpose];
}
