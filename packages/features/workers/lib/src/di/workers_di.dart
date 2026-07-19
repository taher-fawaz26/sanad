import 'package:core/core.dart';
import 'package:network/network.dart';
import 'package:workers/src/data/datasources/worker_remote_data_source.dart';
import 'package:workers/src/data/repositories/worker_repository_impl.dart';
import 'package:workers/src/domain/repositories/worker_repository.dart';
import 'package:workers/src/domain/usecases/delete_worker_usecase.dart';
import 'package:workers/src/domain/usecases/get_workers_usecase.dart';
import 'package:workers/src/domain/usecases/update_worker_status_usecase.dart';
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
      ..registerFactory(
        () => WorkersBloc(
          getWorkersUseCase: sl<GetWorkersUseCase>(),
          deleteWorkerUseCase: sl<DeleteWorkerUseCase>(),
          updateWorkerStatusUseCase: sl<UpdateWorkerStatusUseCase>(),
        ),
      );
  }
}
