import 'package:equatable/equatable.dart';

/// `AcceptInvitationDto` — body for `POST /workers/invitations/accept`.
class AcceptInvitationRequest extends Equatable {
  const AcceptInvitationRequest({required this.token, required this.otp});

  final String token;
  final String otp;

  Map<String, dynamic> toMap() => {'token': token, 'otp': otp};

  @override
  List<Object?> get props => [token, otp];
}
