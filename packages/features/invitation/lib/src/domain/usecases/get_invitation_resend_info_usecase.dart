import 'package:auth/auth.dart' show ResendInfo;
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:invitation/src/domain/repositories/invitation_repository.dart';
import 'package:invitation/src/domain/usecases/usecase_params.dart';

/// `GET /workers/invitations/resend-info/{token}` — server-driven resend
/// cooldown.
class GetInvitationResendInfoUseCase
    implements UseCase<ResendInfo, InvitationTokenParams> {
  const GetInvitationResendInfoUseCase(this._repository);

  final InvitationRepository _repository;

  @override
  TaskEither<Failure, ResendInfo> call(InvitationTokenParams params) =>
      _repository.getResendInfo(params);
}
