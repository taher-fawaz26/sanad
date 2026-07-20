import 'package:core/core.dart';
import 'package:network/network.dart';
import 'package:workers/src/data/datasources/branch_option_remote_data_source.dart';
import 'package:workers/src/data/datasources/worker_remote_data_source.dart';
import 'package:workers/src/data/repositories/worker_repository_impl.dart';
import 'package:workers/src/domain/repositories/worker_repository.dart';
import 'package:workers/src/domain/usecases/cancel_invitation_usecase.dart';
import 'package:workers/src/domain/usecases/delete_worker_usecase.dart';
import 'package:workers/src/domain/usecases/get_invitations_usecase.dart';
import 'package:workers/src/domain/usecases/get_workers_usecase.dart';
import 'package:workers/src/domain/usecases/invite_worker_usecase.dart';
import 'package:workers/src/domain/usecases/resend_invitation_usecase.dart';
import 'package:workers/src/domain/usecases/update_worker_status_usecase.dart';
import 'package:workers/src/domain/usecases/update_worker_usecase.dart';
import 'package:workers/src/presentation/bloc/add_worker/add_worker_bloc.dart';
import 'package:workers/src/presentation/bloc/edit_worker/edit_worker_bloc.dart';
import 'package:workers/src/presentation/bloc/workers/workers_bloc.dart';

abstract final class WorkersDI {
  WorkersDI._();

  static void init() {
    sl
      ..registerLazySingleton<WorkerRemoteDataSource>(
        () => WorkerRemoteDataSourceImpl(sl<BaseApiClient>()),
      )
      ..registerLazySingleton<WorkerRepository>(
        () => WorkerRepositoryImpl(sl<WorkerRemoteDataSource>()),
      )
      ..registerLazySingleton(
        () => GetWorkersUseCase(sl<WorkerRepository>()),
      )
      ..registerLazySingleton(
        () => DeleteWorkerUseCase(sl<WorkerRepository>()),
      )
      ..registerLazySingleton(
        () => UpdateWorkerStatusUseCase(sl<WorkerRepository>()),
      )
      ..registerLazySingleton(
        () => GetInvitationsUseCase(sl<WorkerRepository>()),
      )
      ..registerLazySingleton(
        () => InviteWorkerUseCase(sl<WorkerRepository>()),
      )
      ..registerLazySingleton(
        () => ResendInvitationUseCase(sl<WorkerRepository>()),
      )
      ..registerLazySingleton(
        () => CancelInvitationUseCase(sl<WorkerRepository>()),
      )
      ..registerLazySingleton(
        () => UpdateWorkerUseCase(sl<WorkerRepository>()),
      )
      ..registerLazySingleton<BranchOptionRemoteDataSource>(
        () => BranchOptionRemoteDataSourceImpl(sl<BaseApiClient>()),
      )
      ..registerFactory(
        () => WorkersBloc(
          getWorkersUseCase: sl<GetWorkersUseCase>(),
          deleteWorkerUseCase: sl<DeleteWorkerUseCase>(),
          updateWorkerStatusUseCase: sl<UpdateWorkerStatusUseCase>(),
          getInvitationsUseCase: sl<GetInvitationsUseCase>(),
          resendInvitationUseCase: sl<ResendInvitationUseCase>(),
          cancelInvitationUseCase: sl<CancelInvitationUseCase>(),
        ),
      )
      ..registerFactory(
        () => AddWorkerBloc(inviteWorkerUseCase: sl<InviteWorkerUseCase>()),
      )
      ..registerFactory(
        () => EditWorkerBloc(updateWorkerUseCase: sl<UpdateWorkerUseCase>()),
      );
  }
}
