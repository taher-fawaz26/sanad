import 'package:auth/auth.dart' show AuthSessionEntity;
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:invitation/src/domain/repositories/invitation_repository.dart';
import 'package:invitation/src/domain/usecases/usecase_params.dart';

/// `POST /workers/invitations/accept` — verifies the OTP and accepts the
/// invitation, resolving to the same full-session shape as `auth/profile`.
class AcceptInvitationUseCase
    implements UseCase<AuthSessionEntity, AcceptInvitationParams> {
  const AcceptInvitationUseCase(this._repository);

  final InvitationRepository _repository;

  @override
  TaskEither<Failure, AuthSessionEntity> call(
    AcceptInvitationParams params,
  ) => _repository.accept(params);
}
