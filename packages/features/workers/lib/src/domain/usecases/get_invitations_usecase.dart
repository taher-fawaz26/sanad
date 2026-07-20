import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:workers/src/domain/entities/invitation_entity.dart';
import 'package:workers/src/domain/repositories/worker_repository.dart';

class GetInvitationsUseCase
    implements UseCase<List<InvitationEntity>, NoParams> {
  const GetInvitationsUseCase(this._repository);

  final WorkerRepository _repository;

  @override
  TaskEither<Failure, List<InvitationEntity>> call(NoParams params) =>
      _repository.getInvitations();
}
