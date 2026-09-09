import 'package:core/core.dart';
import 'package:network/network.dart';
import 'package:sanad_provider/src/features/requests/src/data/datasources/provider_requests_remote_data_source.dart';
import 'package:sanad_provider/src/features/requests/src/data/repositories/provider_requests_repository_impl.dart';
import 'package:sanad_provider/src/features/requests/src/domain/repositories/provider_requests_repository.dart';
import 'package:sanad_provider/src/features/requests/src/domain/usecases/provider_request_usecases.dart';
import 'package:sanad_provider/src/features/requests/src/presentation/bloc/workspace/provider_requests_workspace_bloc.dart';

/// Dependency registration for the provider request workspace.
///
/// The detail bloc is not registered here: it is per-request, so the route
/// builds it with the id it was opened for.
abstract final class ProviderRequestsDI {
  ProviderRequestsDI._();

  /// Registers the feature's data source, repository, use cases and the
  /// workspace bloc.
  static void init() {
    sl
      ..registerLazySingleton<ProviderRequestsRemoteDataSource>(
        () => ProviderRequestsRemoteDataSourceImpl(sl<BaseApiClient>()),
      )
      ..registerLazySingleton<ProviderRequestsRepository>(
        () => ProviderRequestsRepositoryImpl(
          sl<ProviderRequestsRemoteDataSource>(),
        ),
      )
      ..registerLazySingleton(
        () => ListProviderRequestsUseCase(sl<ProviderRequestsRepository>()),
      )
      ..registerLazySingleton(
        () => GetProviderRequestCountsUseCase(sl<ProviderRequestsRepository>()),
      )
      ..registerLazySingleton(
        () => GetProviderRequestStatsUseCase(sl<ProviderRequestsRepository>()),
      )
      ..registerLazySingleton(
        () => GetProviderRequestUseCase(sl<ProviderRequestsRepository>()),
      )
      ..registerLazySingleton(
        () => CreateProviderOfferUseCase(sl<ProviderRequestsRepository>()),
      )
      ..registerLazySingleton(
        () => WithdrawProviderOfferUseCase(sl<ProviderRequestsRepository>()),
      )
      ..registerLazySingleton(
        () => AcceptClientCounterUseCase(sl<ProviderRequestsRepository>()),
      )
      ..registerLazySingleton(
        () => DeclineClientCounterUseCase(sl<ProviderRequestsRepository>()),
      )
      ..registerLazySingleton(
        () => CounterClientOfferUseCase(sl<ProviderRequestsRepository>()),
      )
      ..registerLazySingleton(
        () => CompleteProviderJobUseCase(sl<ProviderRequestsRepository>()),
      )
      ..registerLazySingleton(
        () => CancelProviderJobUseCase(sl<ProviderRequestsRepository>()),
      )
      ..registerFactory(
        () => ProviderRequestsWorkspaceBloc(
          listRequests: sl<ListProviderRequestsUseCase>(),
          getCounts: sl<GetProviderRequestCountsUseCase>(),
          getStats: sl<GetProviderRequestStatsUseCase>(),
        ),
      );
  }
}
