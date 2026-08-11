import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:sanad_provider/src/features/invitation/src/domain/repositories/invitation_repository.dart';
import 'package:sanad_provider/src/features/invitation/src/domain/usecases/usecase_params.dart';

/// `POST /workers/invitations/resend-otp` — resends an already-active OTP.
class ResendInvitationOtpUseCase
    implements UseCase<void, InvitationTokenParams> {
  const ResendInvitationOtpUseCase(this._repository);

  final InvitationRepository _repository;

  @override
  TaskEither<Failure, void> call(InvitationTokenParams params) =>
      _repository.resendOtp(params);
}
