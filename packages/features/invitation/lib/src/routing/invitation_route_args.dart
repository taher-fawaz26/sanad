import 'package:auth/auth.dart' show AuthSessionEntity;
import 'package:equatable/equatable.dart';
import 'package:invitation/src/domain/entities/invitation_preview_entity.dart';

/// `extra` payload for `InvitationRoutes.otp` — carries the token forward
/// (verify-token already ran on the details page) plus the resolved
/// [preview] so the OTP screen doesn't need to re-fetch it.
class InvitationOtpRouteArgs extends Equatable {
  const InvitationOtpRouteArgs({required this.token, required this.preview});

  final String token;
  final InvitationPreview preview;

  @override
  List<Object?> get props => [token, preview];
}

/// `extra` payload for `InvitationRoutes.success` — the [preview] (for
/// display copy) and the freshly accepted [session].
class InvitationSuccessRouteArgs extends Equatable {
  const InvitationSuccessRouteArgs({
    required this.preview,
    required this.session,
  });

  final InvitationPreview preview;
  final AuthSessionEntity session;

  @override
  List<Object?> get props => [preview, session];
}
