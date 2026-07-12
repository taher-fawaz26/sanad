import 'package:equatable/equatable.dart';
import 'package:otp/src/domain/enums/otp_purpose.dart';

class ValidateOtpRequest extends Equatable {
  const ValidateOtpRequest({
    required this.identifier,
    required this.otp,
    this.purpose = OtpPurpose.register,
  });

  final String identifier;
  final int otp;
  final OtpPurpose purpose;

  Map<String, dynamic> toMap() => {
        'identifier': identifier,
        'otp': otp,
        'purpose': purpose.wireValue,
      };

  @override
  List<Object?> get props => [identifier, otp, purpose];
}
