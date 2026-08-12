import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:workers/src/domain/entities/worker_entity.dart';
import 'package:workers/src/domain/repositories/worker_repository.dart';
import 'package:workers/src/domain/usecases/workers_query.dart';

export 'package:workers/src/domain/usecases/workers_query.dart';

class GetWorkersUseCase implements UseCase<Page<WorkerEntity>, WorkersQuery> {
  const GetWorkersUseCase(this._repository);

  final WorkerRepository _repository;

  @override
  TaskEither<Failure, Page<WorkerEntity>> call(WorkersQuery query) =>
      _repository.getWorkers(query);
}
