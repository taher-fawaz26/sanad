import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';
import 'package:workers/src/data/endpoints/worker_api_paths.dart';
import 'package:workers/src/data/models/worker_dto.dart';

abstract interface class WorkerRemoteDataSource {
  TaskEither<Failure, List<WorkerDto>> getWorkers();
}

class WorkerRemoteDataSourceImpl implements WorkerRemoteDataSource {
  const WorkerRemoteDataSourceImpl(this._apiClient);

  final BaseApiClient _apiClient;

  @override
  TaskEither<Failure, List<WorkerDto>> getWorkers() =>
      _apiClient.request<List<WorkerDto>>(
        path: WorkerApiPaths.workers,
        method: RequestMethod.get,
        query: const {'type': 'worker', 'status': 'active'},
        parser: (data) =>
            ((data as Map<String, dynamic>)['data'] as List<dynamic>)
                .map((e) => WorkerDto.fromJson(e as Map<String, dynamic>))
                .toList(),
      );
}
