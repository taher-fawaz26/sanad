import 'package:core/core.dart';
import 'package:network/network.dart';
import 'package:workers/src/data/datasources/worker_remote_data_source.dart';
import 'package:workers/src/data/repositories/worker_repository_impl.dart';
import 'package:workers/src/domain/repositories/worker_repository.dart';
import 'package:workers/src/domain/usecases/cancel_invitation_usecase.dart';
import 'package:workers/src/domain/usecases/delete_invitation_usecase.dart';
import 'package:workers/src/domain/usecases/delete_worker_usecase.dart';
import 'package:workers/src/domain/usecases/get_invitations_usecase.dart';
import 'package:workers/src/domain/usecases/get_worker_usecase.dart';
import 'package:workers/src/domain/usecases/get_workers_usecase.dart';
import 'package:workers/src/domain/usecases/invite_worker_usecase.dart';
import 'package:workers/src/domain/usecases/resend_invitation_usecase.dart';
import 'package:workers/src/domain/usecases/update_worker_status_usecase.dart';
import 'package:workers/src/domain/usecases/update_worker_usecase.dart';
import 'package:workers/src/presentation/bloc/add_worker/add_worker_bloc.dart';
import 'package:workers/src/presentation/bloc/edit_worker/edit_worker_bloc.dart';
import 'package:workers/src/presentation/bloc/invitation_action/invitation_action_cubit.dart';
import 'package:workers/src/presentation/bloc/invitations_list/invitations_list_bloc.dart';
import 'package:workers/src/presentation/bloc/worker_action/worker_action_cubit.dart';
import 'package:workers/src/presentation/bloc/workers_list/workers_list_bloc.dart';

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
        () => GetWorkerUseCase(sl<WorkerRepository>()),
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
        () => DeleteInvitationUseCase(sl<WorkerRepository>()),
      )
      ..registerLazySingleton(
        () => UpdateWorkerUseCase(sl<WorkerRepository>()),
      )
      ..registerFactory(
        () => WorkersListBloc(getWorkersUseCase: sl<GetWorkersUseCase>()),
      )
      ..registerFactory(
        () => InvitationsListBloc(
          getInvitationsUseCase: sl<GetInvitationsUseCase>(),
        ),
      )
      ..registerFactory(
        () => WorkerActionCubit(
          deleteWorkerUseCase: sl<DeleteWorkerUseCase>(),
          updateWorkerStatusUseCase: sl<UpdateWorkerStatusUseCase>(),
        ),
      )
      ..registerFactory(
        () => InvitationActionCubit(
          resendInvitationUseCase: sl<ResendInvitationUseCase>(),
          cancelInvitationUseCase: sl<CancelInvitationUseCase>(),
          deleteInvitationUseCase: sl<DeleteInvitationUseCase>(),
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
