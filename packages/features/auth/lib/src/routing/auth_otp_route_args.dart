import 'package:auth/src/domain/enums/auth_flow_intent.dart';
import 'package:equatable/equatable.dart';

/// `extra` payload for [AuthRoutes.otp] (see `AuthShell.otpRoute`).
///
/// The shared OTP screen must know [intent] to verify against the right
/// endpoint (`login/verify` vs `signup/verify`) — a bare email string, as
/// the route used to carry, is no longer enough now that login and signup
/// are separate endpoint pairs.
class AuthOtpRouteArgs extends Equatable {
  const AuthOtpRouteArgs({required this.email, required this.intent});

  final String email;
  final AuthFlowIntent intent;

  @override
  List<Object?> get props => [email, intent];
}
