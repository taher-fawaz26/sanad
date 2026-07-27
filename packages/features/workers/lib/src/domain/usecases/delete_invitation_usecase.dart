import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:workers/src/domain/repositories/worker_repository.dart';

class DeleteInvitationParams extends Equatable {
  const DeleteInvitationParams({required this.id});

  final String id;

  @override
  List<Object?> get props => [id];
}

class DeleteInvitationUseCase
    implements UseCase<Unit, DeleteInvitationParams> {
  const DeleteInvitationUseCase(this._repository);

  final WorkerRepository _repository;

  @override
  TaskEither<Failure, Unit> call(DeleteInvitationParams params) =>
      _repository.deleteInvitation(params.id);
}
