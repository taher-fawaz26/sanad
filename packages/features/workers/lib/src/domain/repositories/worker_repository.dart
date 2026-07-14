import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:workers/src/domain/entities/worker_entity.dart';

abstract interface class WorkerRepository {
  TaskEither<Failure, List<WorkerEntity>> getWorkers();
}
