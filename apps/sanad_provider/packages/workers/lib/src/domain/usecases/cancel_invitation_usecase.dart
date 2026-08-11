import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:workers/src/domain/repositories/worker_repository.dart';

class CancelInvitationParams extends Equatable {
  const CancelInvitationParams({required this.id});

  final String id;

  @override
  List<Object?> get props => [id];
}

class CancelInvitationUseCase implements UseCase<Unit, CancelInvitationParams> {
  const CancelInvitationUseCase(this._repository);

  final WorkerRepository _repository;

  @override
  TaskEither<Failure, Unit> call(CancelInvitationParams params) =>
      _repository.cancelInvitation(params.id);
}
