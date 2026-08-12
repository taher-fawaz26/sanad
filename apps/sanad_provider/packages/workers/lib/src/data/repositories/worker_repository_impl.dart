import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:workers/src/data/datasources/worker_remote_data_source.dart';
import 'package:workers/src/domain/entities/invitation_entity.dart';
import 'package:workers/src/domain/entities/worker_entity.dart';
import 'package:workers/src/domain/entities/worker_status.dart';
import 'package:workers/src/domain/repositories/worker_repository.dart';
import 'package:workers/src/domain/usecases/invitations_query.dart';
import 'package:workers/src/domain/usecases/invite_worker_usecase.dart';
import 'package:workers/src/domain/usecases/update_worker_usecase.dart';
import 'package:workers/src/domain/usecases/workers_query.dart';

class WorkerRepositoryImpl implements WorkerRepository {
  const WorkerRepositoryImpl(this._remoteDataSource);

  final WorkerRemoteDataSource _remoteDataSource;

  @override
  TaskEither<Failure, Page<WorkerEntity>> getWorkers(WorkersQuery query) =>
      _remoteDataSource
          .getWorkers(query)
          .map((page) => page.mapItems((dto) => dto.toEntity()));

  @override
  TaskEither<Failure, WorkerEntity> getWorker(String id) =>
      _remoteDataSource.getWorker(id).map((dto) => dto.toEntity());

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
  TaskEither<Failure, Page<InvitationEntity>> getInvitations(
    InvitationsQuery query,
  ) => _remoteDataSource
      .getInvitations(query)
      .map((page) => page.mapItems((dto) => dto.toEntity()));

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
  TaskEither<Failure, Unit> deleteInvitation(String id) =>
      _remoteDataSource.deleteInvitation(id);

  @override
  TaskEither<Failure, WorkerEntity> updateWorker(UpdateWorkerParams params) =>
      _remoteDataSource.updateWorker(params).map((dto) => dto.toEntity());
}
