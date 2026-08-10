import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:invitation/src/domain/repositories/invitation_repository.dart';
import 'package:invitation/src/domain/usecases/usecase_params.dart';

/// `POST /workers/invitations/request-otp` — sends the first OTP.
class RequestInvitationOtpUseCase
    implements UseCase<void, InvitationTokenParams> {
  const RequestInvitationOtpUseCase(this._repository);

  final InvitationRepository _repository;

  @override
  TaskEither<Failure, void> call(InvitationTokenParams params) =>
      _repository.requestOtp(params);
}
