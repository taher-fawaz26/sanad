import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:workers/src/domain/entities/invitation_entity.dart';
import 'package:workers/src/domain/entities/worker_entity.dart';
import 'package:workers/src/domain/entities/worker_status.dart';
import 'package:workers/src/domain/usecases/invitations_query.dart';
import 'package:workers/src/domain/usecases/invite_worker_usecase.dart';
import 'package:workers/src/domain/usecases/update_worker_usecase.dart';
import 'package:workers/src/domain/usecases/workers_query.dart';

abstract interface class WorkerRepository {
  TaskEither<Failure, Page<WorkerEntity>> getWorkers(WorkersQuery query);
  TaskEither<Failure, WorkerEntity> getWorker(String id);
  TaskEither<Failure, Unit> deleteWorker(String id);
  TaskEither<Failure, WorkerEntity> updateWorkerStatus(
    String id,
    WorkerStatus status,
  );
  TaskEither<Failure, Page<InvitationEntity>> getInvitations(
    InvitationsQuery query,
  );
  TaskEither<Failure, Unit> inviteWorker(InviteWorkerParams params);
  TaskEither<Failure, Unit> resendInvitation(String id);
  TaskEither<Failure, Unit> cancelInvitation(String id);
  TaskEither<Failure, Unit> deleteInvitation(String id);
  TaskEither<Failure, WorkerEntity> updateWorker(UpdateWorkerParams params);
}
