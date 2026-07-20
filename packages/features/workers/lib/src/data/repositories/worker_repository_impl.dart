import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:workers/src/data/datasources/worker_remote_data_source.dart';
import 'package:workers/src/domain/entities/invitation_entity.dart';
import 'package:workers/src/domain/entities/worker_entity.dart';
import 'package:workers/src/domain/entities/worker_status.dart';
import 'package:workers/src/domain/repositories/worker_repository.dart';
import 'package:workers/src/domain/usecases/invite_worker_usecase.dart';
import 'package:workers/src/domain/usecases/update_worker_usecase.dart';

class WorkerRepositoryImpl implements WorkerRepository {
  const WorkerRepositoryImpl(this._remoteDataSource);

  final WorkerRemoteDataSource _remoteDataSource;

  @override
  TaskEither<Failure, List<WorkerEntity>> getWorkers() =>
      _remoteDataSource.getWorkers().map(
        (dtos) => dtos.map((dto) => dto.toEntity()).toList(),
      );

  @override
  TaskEither<Failure, Unit> deleteWorker(String id) =>
      _remoteDataSource.deleteWorker(id);

  @override
  TaskEither<Failure, WorkerEntity> updateWorkerStatus(
    String id,
    WorkerStatus status,
  ) => _remoteDataSource
      .updateWorkerStatus(id, status)
      .map((dto) => dto.toEntity());

  @override
  TaskEither<Failure, List<InvitationEntity>> getInvitations() =>
      _remoteDataSource.getInvitations().map(
        (dtos) => dtos.map((dto) => dto.toEntity()).toList(),
      );

  @override
  TaskEither<Failure, Unit> inviteWorker(InviteWorkerParams params) =>
      _remoteDataSource.inviteWorker(params);

  @override
  TaskEither<Failure, Unit> resendInvitation(String id) =>
      _remoteDataSource.resendInvitation(id);

  @override
  TaskEither<Failure, Unit> cancelInvitation(String id) =>
      _remoteDataSource.cancelInvitation(id);

  @override
  TaskEither<Failure, WorkerEntity> updateWorker(UpdateWorkerParams params) =>
      _remoteDataSource.updateWorker(params).map((dto) => dto.toEntity());
}
