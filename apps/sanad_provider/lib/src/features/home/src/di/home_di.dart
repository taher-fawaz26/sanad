import 'package:core/core.dart';
import 'package:localization/localization.dart';
import 'package:network/network.dart';
import 'package:sanad_provider/src/features/home/src/data/cache/provider_statistics_cache_store.dart';
import 'package:sanad_provider/src/features/home/src/data/datasources/provider_statistics_remote_datasource.dart';
import 'package:sanad_provider/src/features/home/src/data/repositories/provider_statistics_repository_impl.dart';
import 'package:sanad_provider/src/features/home/src/domain/repositories/provider_statistics_repository.dart';
import 'package:sanad_provider/src/features/home/src/domain/usecases/get_provider_statistics_usecase.dart';
import 'package:sanad_provider/src/features/home/src/presentation/bloc/provider_statistics/provider_statistics_bloc.dart';

/// Dependency registration for the provider home dashboard.
abstract final class HomeDI {
  HomeDI._();

  static void init() {
    sl
      ..registerLazySingleton<ProviderStatisticsRemoteDataSource>(
        () => ProviderStatisticsRemoteDataSourceImpl(sl<BaseApiClient>()),
      )
      ..registerLazySingleton<ProviderStatisticsRepository>(
        () => ProviderStatisticsRepositoryImpl(
          sl<ProviderStatisticsRemoteDataSource>(),
          sl<NetworkGuard>(),
        ),
      )
      ..registerLazySingleton(
        () => GetProviderStatisticsUseCase(sl<ProviderStatisticsRepository>()),
      )
      ..registerLazySingleton(ProviderStatisticsCacheStore.new)
      ..registerFactory(
        () => ProviderStatisticsBloc(
          getStatistics: sl<GetProviderStatisticsUseCase>(),
          cacheStore: sl<ProviderStatisticsCacheStore>(),
          resolveLanguageCode: () => sl<TranslateBloc>().state.languageCode,
        ),
      );
  }
}
