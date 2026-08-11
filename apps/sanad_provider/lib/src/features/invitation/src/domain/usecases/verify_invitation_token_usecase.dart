import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:sanad_provider/src/features/invitation/src/domain/entities/invitation_preview_entity.dart';
import 'package:sanad_provider/src/features/invitation/src/domain/repositories/invitation_repository.dart';
import 'package:sanad_provider/src/features/invitation/src/domain/usecases/usecase_params.dart';

/// `GET /workers/verify-token/{token}`.
class VerifyInvitationTokenUseCase
    implements UseCase<InvitationPreview, InvitationTokenParams> {
  const VerifyInvitationTokenUseCase(this._repository);

  final InvitationRepository _repository;

  @override
  TaskEither<Failure, InvitationPreview> call(
    InvitationTokenParams params,
  ) => _repository.verifyToken(params);
}
