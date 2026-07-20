import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';
import 'package:workers/src/data/endpoints/worker_api_paths.dart';
import 'package:workers/src/data/models/invitation_dto.dart';
import 'package:workers/src/data/models/worker_dto.dart';
import 'package:workers/src/domain/entities/worker_status.dart';
import 'package:workers/src/domain/usecases/invite_worker_usecase.dart';
import 'package:workers/src/domain/usecases/update_worker_usecase.dart';

abstract interface class WorkerRemoteDataSource {
  TaskEither<Failure, List<WorkerDto>> getWorkers();
  TaskEither<Failure, Unit> deleteWorker(String id);
  TaskEither<Failure, WorkerDto> updateWorkerStatus(
    String id,
    WorkerStatus status,
  );
  TaskEither<Failure, List<InvitationDto>> getInvitations();
  TaskEither<Failure, Unit> inviteWorker(InviteWorkerParams params);
  TaskEither<Failure, Unit> resendInvitation(String id);
  TaskEither<Failure, Unit> cancelInvitation(String id);
  TaskEither<Failure, WorkerDto> updateWorker(UpdateWorkerParams params);
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
  TaskEither<Failure, Unit> deleteWorker(String id) => _apiClient.request<Unit>(
    path: '${WorkerApiPaths.workers}/$id',
    method: RequestMethod.delete,
    parser: (_) => unit,
  );

  @override
  TaskEither<Failure, WorkerDto> updateWorkerStatus(
    String id,
    WorkerStatus status,
  ) => _apiClient.request<WorkerDto>(
    path: '${WorkerApiPaths.workers}/$id',
    method: RequestMethod.patch,
    body: {'status': status.name},
    parser: (data) => WorkerDto.fromJson(
      (data as Map<String, dynamic>)['data'] as Map<String, dynamic>,
    ),
  );

  @override
  TaskEither<Failure, List<InvitationDto>> getInvitations() =>
      _apiClient.request<List<InvitationDto>>(
        path: WorkerApiPaths.invitations,
        method: RequestMethod.get,
        parser: (data) =>
            ((data as Map<String, dynamic>)['data'] as List<dynamic>)
                .map(
                  (e) => InvitationDto.fromJson(e as Map<String, dynamic>),
                )
                .toList(),
      );

  // TODO(sanad-api): No invite-worker endpoint exists in the sanad-api spec
  // yet (only GET lst-workers-v-1 / lst-invitations-v-1 are registered).
  // Stubbed to unblock UI work; replace with a real _apiClient.request call
  // once the backend exposes this endpoint.
  @override
  TaskEither<Failure, Unit> inviteWorker(InviteWorkerParams params) =>
      TaskEither.tryCatch(
        () async {
          await Future<void>.delayed(const Duration(milliseconds: 800));
          return unit;
        },
        (_, _) => const UnknownFailure(message: 'Unknown error'),
      );

  // TODO(sanad-api): No resend-invitation endpoint exists in the spec yet.
  // Stubbed to unblock UI work.
  @override
  TaskEither<Failure, Unit> resendInvitation(String id) => TaskEither.tryCatch(
    () async {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      return unit;
    },
    (_, _) => const UnknownFailure(message: 'Unknown error'),
  );

  // TODO(sanad-api): No cancel-invitation endpoint exists in the spec yet.
  // Stubbed to unblock UI work.
  @override
  TaskEither<Failure, Unit> cancelInvitation(String id) => TaskEither.tryCatch(
    () async {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      return unit;
    },
    (_, _) => const UnknownFailure(message: 'Unknown error'),
  );

  // TODO(sanad-api): No update-worker endpoint exists in the spec yet.
  // Stubbed to unblock UI work; returns the input echoed back as a WorkerDto.
  @override
  TaskEither<Failure, WorkerDto> updateWorker(UpdateWorkerParams params) =>
      TaskEither.tryCatch(
        () async {
          await Future<void>.delayed(const Duration(milliseconds: 800));
          return WorkerDto(
            id: params.id,
            fullName: params.fullName,
            role: params.type.toApiString(),
            initials: _stubInitials(params.fullName),
            phone: params.phone,
            email: params.email,
            branches: params.branchId,
          );
        },
        (_, _) => const UnknownFailure(message: 'Unknown error'),
      );

  static String _stubInitials(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    return words
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
  }
}
