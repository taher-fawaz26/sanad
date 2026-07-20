import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:workers/src/domain/entities/invitation_entity.dart';
import 'package:workers/src/domain/entities/paged_result.dart';
import 'package:workers/src/domain/entities/worker_entity.dart';
import 'package:workers/src/domain/entities/worker_status.dart';
import 'package:workers/src/domain/usecases/invite_worker_usecase.dart';
import 'package:workers/src/domain/usecases/update_worker_usecase.dart';

abstract interface class WorkerRepository {
  TaskEither<Failure, PagedResult<WorkerEntity>> getWorkers({
    required int page,
    required int limit,
    String? search,
  });
  TaskEither<Failure, WorkerEntity> getWorker(String id);
  TaskEither<Failure, Unit> deleteWorker(String id);
  TaskEither<Failure, WorkerEntity> updateWorkerStatus(
    String id,
    WorkerStatus status,
  );
  TaskEither<Failure, PagedResult<InvitationEntity>> getInvitations({
    required int page,
    required int limit,
    String? search,
  });
  TaskEither<Failure, Unit> inviteWorker(InviteWorkerParams params);
  TaskEither<Failure, Unit> resendInvitation(String id);
  TaskEither<Failure, Unit> cancelInvitation(String id);
  TaskEither<Failure, WorkerEntity> updateWorker(UpdateWorkerParams params);
}
