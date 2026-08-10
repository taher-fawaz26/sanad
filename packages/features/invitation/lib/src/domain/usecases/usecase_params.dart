import 'package:equatable/equatable.dart';

/// Params shared by every call that only needs the invitation token
/// (`verify-token`, `request-otp`, `resend-otp`, `resend-info`).
class InvitationTokenParams extends Equatable {
  const InvitationTokenParams({required this.token});

  final String token;

  @override
  List<Object?> get props => [token];
}

/// Params for `POST /workers/invitations/accept` (`AcceptInvitationDto`).
class AcceptInvitationParams extends Equatable {
  const AcceptInvitationParams({required this.token, required this.otp});

  final String token;
  final String otp;

  @override
  List<Object?> get props => [token, otp];
}
