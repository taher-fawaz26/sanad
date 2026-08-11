import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:workers/src/domain/repositories/worker_repository.dart';

class DeleteWorkerParams extends Equatable {
  const DeleteWorkerParams({required this.id});

  final String id;

  @override
  List<Object?> get props => [id];
}

class DeleteWorkerUseCase implements UseCase<Unit, DeleteWorkerParams> {
  const DeleteWorkerUseCase(this._repository);

  final WorkerRepository _repository;

  @override
  TaskEither<Failure, Unit> call(DeleteWorkerParams params) =>
      _repository.deleteWorker(params.id);
}
