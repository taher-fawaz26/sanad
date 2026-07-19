import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';
import 'package:workers/src/data/endpoints/worker_api_paths.dart';
import 'package:workers/src/data/models/worker_dto.dart';
import 'package:workers/src/domain/entities/worker_status.dart';

abstract interface class WorkerRemoteDataSource {
  TaskEither<Failure, List<WorkerDto>> getWorkers();
  TaskEither<Failure, Unit> deleteWorker(String id);
  TaskEither<Failure, WorkerDto> updateWorkerStatus(
    String id,
    WorkerStatus status,
  );
}

class WorkerRemoteDataSourceImpl implements WorkerRemoteDataSource {
  const WorkerRemoteDataSourceImpl(this._apiClient);

  final BaseApiClient _apiClient;

  @override
  TaskEither<Failure, List<WorkerDto>> getWorkers() =>
      _apiClient.request<List<WorkerDto>>(
        path: WorkerApiPaths.workers,
        method: RequestMethod.get,
        query: const {'type': 'worker'},
        parser: (data) =>
            ((data as Map<String, dynamic>)['data'] as List<dynamic>)
                .map((e) => WorkerDto.fromJson(e as Map<String, dynamic>))
                .toList(),
      );

  @override
  TaskEither<Failure, Unit> deleteWorker(String id) =>
      _apiClient.request<Unit>(
        path: '${WorkerApiPaths.workers}/$id',
        method: RequestMethod.delete,
        parser: (_) => unit,
      );

  @override
  TaskEither<Failure, WorkerDto> updateWorkerStatus(
    String id,
    WorkerStatus status,
  ) =>
      _apiClient.request<WorkerDto>(
        path: '${WorkerApiPaths.workers}/$id',
        method: RequestMethod.patch,
        body: {'status': status.name},
        parser: (data) => WorkerDto.fromJson(
          (data as Map<String, dynamic>)['data'] as Map<String, dynamic>,
        ),
      );
}
