import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:workers/src/domain/entities/invitation_entity.dart';
import 'package:workers/src/domain/repositories/worker_repository.dart';
import 'package:workers/src/domain/usecases/invitations_query.dart';

export 'package:workers/src/domain/usecases/invitations_query.dart';

class GetInvitationsUseCase
    implements UseCase<Page<InvitationEntity>, InvitationsQuery> {
  const GetInvitationsUseCase(this._repository);

  final WorkerRepository _repository;

  @override
  TaskEither<Failure, Page<InvitationEntity>> call(InvitationsQuery query) =>
      _repository.getInvitations(query);
}
