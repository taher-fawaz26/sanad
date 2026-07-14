import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:workers/src/data/datasources/worker_remote_data_source.dart';
import 'package:workers/src/domain/entities/worker_entity.dart';
import 'package:workers/src/domain/repositories/worker_repository.dart';

class WorkerRepositoryImpl implements WorkerRepository {
  const WorkerRepositoryImpl(this._remoteDataSource);

  final WorkerRemoteDataSource _remoteDataSource;

  @override
  TaskEither<Failure, List<WorkerEntity>> getWorkers() =>
      _remoteDataSource.getWorkers().map(
            (dtos) => dtos.map((dto) => dto.toEntity()).toList(),
          );
}
