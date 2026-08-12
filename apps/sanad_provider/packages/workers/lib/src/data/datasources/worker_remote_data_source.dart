import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';
import 'package:workers/src/data/endpoints/worker_api_paths.dart';
import 'package:workers/src/data/models/create_invitation_dto.dart';
import 'package:workers/src/data/models/invitation_dto.dart';
import 'package:workers/src/data/models/update_worker_dto.dart';
import 'package:workers/src/data/models/update_worker_status_dto.dart';
import 'package:workers/src/data/models/worker_dto.dart';
import 'package:workers/src/domain/entities/worker_status.dart';
import 'package:workers/src/domain/usecases/invitations_query.dart';
import 'package:workers/src/domain/usecases/invite_worker_usecase.dart';
import 'package:workers/src/domain/usecases/update_worker_usecase.dart';
import 'package:workers/src/domain/usecases/workers_query.dart';

abstract interface class WorkerRemoteDataSource {
  TaskEither<Failure, Page<WorkerDto>> getWorkers(WorkersQuery query);
  TaskEither<Failure, WorkerDto> getWorker(String id);
  TaskEither<Failure, Unit> deleteWorker(String id);
  TaskEither<Failure, WorkerDto> updateWorkerStatus(
    String id,
    WorkerStatus status,
  );
  TaskEither<Failure, Page<InvitationDto>> getInvitations(
    InvitationsQuery query,
  );
  TaskEither<Failure, Unit> inviteWorker(InviteWorkerParams params);
  TaskEither<Failure, Unit> resendInvitation(String id);
  TaskEither<Failure, Unit> cancelInvitation(String id);
  TaskEither<Failure, Unit> deleteInvitation(String id);
  TaskEither<Failure, WorkerDto> updateWorker(UpdateWorkerParams params);
}

class WorkerRemoteDataSourceImpl implements WorkerRemoteDataSource {
  const WorkerRemoteDataSourceImpl(this._apiClient);

  final BaseApiClient _apiClient;

  /// Single-worker responses (`WorkerProfileResponseDto`) may be returned bare
  /// or wrapped in a `{data: {...}}` envelope; handle both.
  static WorkerDto _parseWorker(dynamic data) {
    final map = data as Map<String, dynamic>;
    final payload = map['data'] as Map<String, dynamic>? ?? map;
    return WorkerDto.fromJson(payload);
  }

  @override
  TaskEither<Failure, Page<WorkerDto>> getWorkers(WorkersQuery query) =>
      _apiClient.request<Page<WorkerDto>>(
        path: WorkerApiPaths.workers,
        method: RequestMethod.get,
        query: query.toQueryMap(),
        parser: (data) => parsePage(data, WorkerDto.fromJson),
      );

  @override
  TaskEither<Failure, WorkerDto> getWorker(String id) =>
      _apiClient.request<WorkerDto>(
        path: WorkerApiPaths.worker(id),
        method: RequestMethod.get,
        parser: _parseWorker,
      );

  @override
  TaskEither<Failure, Unit> deleteWorker(String id) => _apiClient.request<Unit>(
    path: WorkerApiPaths.worker(id),
    method: RequestMethod.delete,
    parser: (_) => unit,
  );

  @override
  TaskEither<Failure, WorkerDto> updateWorkerStatus(
    String id,
    WorkerStatus status,
  ) => _apiClient.request<WorkerDto>(
    path: WorkerApiPaths.workerStatus(id),
    method: RequestMethod.patch,
    body: UpdateWorkerStatusDto.fromStatus(status).toJson(),
    parser: _parseWorker,
  );

  @override
  TaskEither<Failure, Page<InvitationDto>> getInvitations(
    InvitationsQuery query,
  ) => _apiClient.request<Page<InvitationDto>>(
    path: WorkerApiPaths.invitations,
    method: RequestMethod.get,
    query: query.toQueryMap(),
    parser: (data) => parsePage(data, InvitationDto.fromJson),
  );

  @override
  TaskEither<Failure, Unit> inviteWorker(InviteWorkerParams params) =>
      _apiClient.request<Unit>(
        path: WorkerApiPaths.invitations,
        method: RequestMethod.post,
        body: CreateInvitationDto.fromParams(params).toJson(),
        parser: (_) => unit,
      );

  @override
  TaskEither<Failure, Unit> resendInvitation(String id) =>
      _apiClient.request<Unit>(
        path: WorkerApiPaths.resendInvitation(id),
        method: RequestMethod.post,
        parser: (_) => unit,
      );

  @override
  TaskEither<Failure, Unit> cancelInvitation(String id) =>
      _apiClient.request<Unit>(
        path: WorkerApiPaths.cancelInvitation(id),
        method: RequestMethod.post,
        parser: (_) => unit,
      );

  @override
  TaskEither<Failure, Unit> deleteInvitation(String id) =>
      _apiClient.request<Unit>(
        path: WorkerApiPaths.deleteInvitation(id),
        method: RequestMethod.delete,
        parser: (_) => unit,
      );

  @override
  TaskEither<Failure, WorkerDto> updateWorker(UpdateWorkerParams params) =>
      _apiClient.request<WorkerDto>(
        path: WorkerApiPaths.worker(params.id),
        method: RequestMethod.patch,
        body: UpdateWorkerDto.fromParams(params).toJson(),
        parser: _parseWorker,
      );
}
