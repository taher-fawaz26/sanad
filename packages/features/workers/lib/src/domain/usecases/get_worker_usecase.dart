import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:workers/src/domain/entities/worker_entity.dart';
import 'package:workers/src/domain/repositories/worker_repository.dart';

class GetWorkerParams extends Equatable {
  const GetWorkerParams(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

class GetWorkerUseCase implements UseCase<WorkerEntity, GetWorkerParams> {
  const GetWorkerUseCase(this._repository);

  final WorkerRepository _repository;

  @override
  TaskEither<Failure, WorkerEntity> call(GetWorkerParams params) =>
      _repository.getWorker(params.id);
}
