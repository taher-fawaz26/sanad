import 'package:auth/src/domain/enums/client_auth_method.dart';
import 'package:equatable/equatable.dart';

/// Body for `POST auth/client/verify`.
///
/// [value] must exactly match the identifier used in the paired
/// `request-otp`; [otp] is exactly 6 digits.
class VerifyClientOtpRequest extends Equatable {
  const VerifyClientOtpRequest({
    required this.method,
    required this.value,
    required this.otp,
  });

  final ClientAuthMethod method;
  final String value;
  final String otp;

  Map<String, dynamic> toMap() => {
    'method': method.value,
    'value': value,
    'otp': otp,
  };

  @override
  List<Object?> get props => [method, value, otp];
}
