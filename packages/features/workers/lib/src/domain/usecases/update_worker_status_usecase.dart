import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:workers/src/domain/entities/worker_entity.dart';
import 'package:workers/src/domain/entities/worker_status.dart';
import 'package:workers/src/domain/repositories/worker_repository.dart';

class UpdateWorkerStatusParams extends Equatable {
  const UpdateWorkerStatusParams({required this.id, required this.status});

  final String id;
  final WorkerStatus status;

  @override
  List<Object?> get props => [id, status];
}

class UpdateWorkerStatusUseCase
    implements UseCase<WorkerEntity, UpdateWorkerStatusParams> {
  const UpdateWorkerStatusUseCase(this._repository);

  final WorkerRepository _repository;

  @override
  TaskEither<Failure, WorkerEntity> call(UpdateWorkerStatusParams params) =>
      _repository.updateWorkerStatus(params.id, params.status);
}
