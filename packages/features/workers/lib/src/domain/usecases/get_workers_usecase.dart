import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:workers/src/domain/entities/worker_entity.dart';
import 'package:workers/src/domain/repositories/worker_repository.dart';

class GetWorkersUseCase implements UseCase<List<WorkerEntity>, NoParams> {
  const GetWorkersUseCase(this._repository);

  final WorkerRepository _repository;

  @override
  TaskEither<Failure, List<WorkerEntity>> call(NoParams params) =>
      _repository.getWorkers();
}
