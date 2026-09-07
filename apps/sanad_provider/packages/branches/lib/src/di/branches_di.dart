import 'package:branches/src/data/datasources/branch_remote_data_source.dart';
import 'package:branches/src/data/repositories/branch_repository_impl.dart';
import 'package:branches/src/domain/repositories/branch_repository.dart';
import 'package:branches/src/domain/usecases/create_branch_usecase.dart';
import 'package:branches/src/domain/usecases/delete_branch_usecase.dart';
import 'package:branches/src/domain/usecases/get_branch_managers_usecase.dart';
import 'package:branches/src/domain/usecases/get_branch_usecase.dart';
import 'package:branches/src/domain/usecases/get_branches_usecase.dart';
import 'package:branches/src/domain/usecases/get_company_schedule_usecase.dart';
import 'package:branches/src/domain/usecases/update_branch_status_usecase.dart';
import 'package:branches/src/domain/usecases/update_branch_usecase.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_bloc.dart';
import 'package:branches/src/presentation/bloc/assign_branch/assign_branch_bloc.dart';
import 'package:branches/src/presentation/bloc/branch_details/branch_details_bloc.dart';
import 'package:branches/src/presentation/bloc/branch_managers/branch_managers_bloc.dart';
import 'package:branches/src/presentation/bloc/branches/branches_bloc.dart';
import 'package:branches/src/presentation/bloc/swipe_hint/swipe_hint_bloc.dart';
import 'package:branches/src/presentation/widgets/assign_branch_sheet.dart';
import 'package:core/core.dart';
import 'package:network/network.dart';
import 'package:storage/storage.dart';
import 'package:workers/workers.dart';

abstract final class BranchesDI {
  BranchesDI._();

  static void init() {
    sl
      ..registerLazySingleton<BranchRemoteDataSource>(
        () => BranchRemoteDataSourceImpl(sl<BaseApiClient>()),
      )
      ..registerLazySingleton<BranchRepository>(
        () => BranchRepositoryImpl(sl<BranchRemoteDataSource>()),
      )
      ..registerLazySingleton(
        () => GetBranchesUseCase(sl<BranchRepository>()),
      )
      ..registerLazySingleton(
        () => GetBranchUseCase(sl<BranchRepository>()),
      )
      ..registerLazySingleton(
        () => CreateBranchUseCase(sl<BranchRepository>()),
      )
      ..registerLazySingleton(
        () => UpdateBranchUseCase(sl<BranchRepository>()),
      )
      ..registerLazySingleton(
        () => UpdateBranchStatusUseCase(sl<BranchRepository>()),
      )
      ..registerLazySingleton(
        () => DeleteBranchUseCase(sl<BranchRepository>()),
      )
      ..registerLazySingleton(
        () => GetCompanyScheduleUseCase(sl<BranchRepository>()),
      )
      ..registerLazySingleton(
        () => GetBranchManagersUseCase(sl<BranchRepository>()),
      )
      ..registerFactory(
        () => BranchesBloc(
          getBranchesUseCase: sl<GetBranchesUseCase>(),
          deleteBranchUseCase: sl<DeleteBranchUseCase>(),
          updateBranchStatusUseCase: sl<UpdateBranchStatusUseCase>(),
        ),
      )
      ..registerFactory(
        () => AddBranchBloc(
          createBranchUseCase: sl<CreateBranchUseCase>(),
          getCompanyScheduleUseCase: sl<GetCompanyScheduleUseCase>(),
        ),
      )
      ..registerLazySingleton<WorkerBranchAssigner>(
        () => const BranchesWorkerBranchAssigner(),
      )
      ..registerFactory(
        () => BranchManagersBloc(
          getBranchManagersUseCase: sl<GetBranchManagersUseCase>(),
        ),
      )
      ..registerFactory(
        () => SwipeHintBloc(storage: sl<HiveLocalStorage>()),
      )
      ..registerFactoryParam<AssignBranchBloc, WorkerEntity, void>(
        (worker, _) => AssignBranchBloc(
          getBranchesUseCase: sl<GetBranchesUseCase>(),
          updateBranchUseCase: sl<UpdateBranchUseCase>(),
          worker: worker,
        ),
      )
      ..registerFactory(
        () => BranchDetailsBloc(
          getBranchUseCase: sl<GetBranchUseCase>(),
          updateBranchStatusUseCase: sl<UpdateBranchStatusUseCase>(),
          updateBranchUseCase: sl<UpdateBranchUseCase>(),
          getCompanyScheduleUseCase: sl<GetCompanyScheduleUseCase>(),
        ),
      );
  }
}
