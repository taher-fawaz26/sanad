import 'package:equatable/equatable.dart';

/// `RequestInvitationOtpDto` — body shared by `POST
/// /workers/invitations/request-otp` and `POST
/// /workers/invitations/resend-otp`.
class InvitationTokenRequest extends Equatable {
  const InvitationTokenRequest({required this.token});

  final String token;

  Map<String, dynamic> toMap() => {'token': token};

  @override
  List<Object?> get props => [token];
}
