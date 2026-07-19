import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:workers/src/domain/entities/worker_entity.dart';
import 'package:workers/src/domain/entities/worker_status.dart';

abstract interface class WorkerRepository {
  TaskEither<Failure, List<WorkerEntity>> getWorkers();
  TaskEither<Failure, Unit> deleteWorker(String id);
  TaskEither<Failure, WorkerEntity> updateWorkerStatus(
    String id,
    WorkerStatus status,
  );
}
