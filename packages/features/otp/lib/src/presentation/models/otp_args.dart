import 'package:equatable/equatable.dart';

/// Whether the OTP was sent to email or phone.
enum IdentifierType { email, phone }

/// Which auth flow triggered OTP verification.
enum OtpFlow { register, forgotPassword }

/// GoRouter `extra` for [VerificationCodePage].
class OtpArgs extends Equatable {
  const OtpArgs({
    required this.identifier,
    required this.type,
    this.flow = OtpFlow.register,
  });

  final String identifier;
  final IdentifierType type;
  final OtpFlow flow;

  String get channelLabelKey =>
      type == IdentifierType.phone ? 'auth.phone' : 'auth.email';

  @override
  List<Object?> get props => [identifier, type, flow];
}
