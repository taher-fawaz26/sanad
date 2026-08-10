import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:invitation/src/domain/entities/invitation_preview_entity.dart';
import 'package:invitation/src/domain/usecases/usecase_params.dart';

abstract class InvitationRepository {
  /// `GET /workers/verify-token/{token}`.
  TaskEither<Failure, InvitationPreview> verifyToken(
    InvitationTokenParams params,
  );

  /// Step 1 — sends the first OTP for the invitation.
  TaskEither<Failure, void> requestOtp(InvitationTokenParams params);

  /// Resends an already-active OTP.
  TaskEither<Failure, void> resendOtp(InvitationTokenParams params);

  /// Server-driven resend cooldown for the given invitation token.
  TaskEither<Failure, ResendInfo> getResendInfo(InvitationTokenParams params);

  /// Verifies the OTP and accepts the invitation, resolving to the same
  /// full-session shape as `auth/profile`.
  TaskEither<Failure, AuthSessionEntity> accept(AcceptInvitationParams params);
}
