import 'package:activity_logs/src/cache/activity_log_cache_store.dart';
import 'package:activity_logs/src/data/datasources/activity_log_remote_data_source.dart';
import 'package:activity_logs/src/data/repositories/activity_log_repository_impl.dart';
import 'package:activity_logs/src/domain/repositories/activity_log_repository.dart';
import 'package:activity_logs/src/domain/usecases/get_activity_logs_usecase.dart';
import 'package:activity_logs/src/presentation/bloc/recent_activity/recent_activity_cubit.dart';
import 'package:activity_logs/src/presentation/bloc/worker_activity/worker_activity_cubit.dart';
import 'package:core/core.dart';
import 'package:network/network.dart';

abstract final class ActivityLogsDI {
  ActivityLogsDI._();

  static void init() {
    sl
      ..registerLazySingleton<ActivityLogRemoteDataSource>(
        () => ActivityLogRemoteDataSourceImpl(sl<BaseApiClient>()),
      )
      ..registerLazySingleton<ActivityLogRepository>(
        () => ActivityLogRepositoryImpl(sl<ActivityLogRemoteDataSource>()),
      )
      ..registerLazySingleton(
        () => GetActivityLogsUseCase(sl<ActivityLogRepository>()),
      )
      ..registerLazySingleton(ActivityLogCacheStore.new)
      ..registerFactory(
        () => WorkerActivityCubit(
          getActivityLogsUseCase: sl<GetActivityLogsUseCase>(),
          cacheStore: sl<ActivityLogCacheStore>(),
        ),
      )
      ..registerFactory(
        () => RecentActivityCubit(
          getActivityLogsUseCase: sl<GetActivityLogsUseCase>(),
          cacheStore: sl<ActivityLogCacheStore>(),
        ),
      );
  }
}
