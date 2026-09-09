import 'package:core/core.dart';
import 'package:network/network.dart';
import 'package:sanad_client/src/features/client_requests/src/data/datasources/catalogue_remote_data_source.dart';
import 'package:sanad_client/src/features/client_requests/src/data/datasources/client_requests_remote_data_source.dart';
import 'package:sanad_client/src/features/client_requests/src/data/repositories/catalogue_repository_impl.dart';
import 'package:sanad_client/src/features/client_requests/src/data/repositories/client_requests_repository_impl.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/repositories/catalogue_repository.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/repositories/client_requests_repository.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/usecases/client_request_usecases.dart';
import 'package:sanad_client/src/features/client_requests/src/presentation/bloc/client_requests_list/client_requests_list_bloc.dart';
import 'package:sanad_client/src/features/client_requests/src/presentation/bloc/request_draft/request_draft_bloc.dart';

/// Dependency registration for the client request lifecycle.
///
/// The detail bloc is not registered here: it is per-request, so the route
/// builds it directly with the id it was opened for.
abstract final class ClientRequestsDI {
  ClientRequestsDI._();

  /// Registers the feature's data sources, repositories, use cases and the
  /// blocs that need no route parameter.
  static void init() {
    sl
      ..registerLazySingleton<ClientRequestsRemoteDataSource>(
        () => ClientRequestsRemoteDataSourceImpl(sl<BaseApiClient>()),
      )
      ..registerLazySingleton<ClientRequestsRepository>(
        () => ClientRequestsRepositoryImpl(
          sl<ClientRequestsRemoteDataSource>(),
        ),
      )
      ..registerLazySingleton<CatalogueRemoteDataSource>(
        () => CatalogueRemoteDataSourceImpl(sl<BaseApiClient>()),
      )
      ..registerLazySingleton<CatalogueRepository>(
        () => CatalogueRepositoryImpl(sl<CatalogueRemoteDataSource>()),
      )
      ..registerLazySingleton(
        () => ListClientRequestsUseCase(sl<ClientRequestsRepository>()),
      )
      ..registerLazySingleton(
        () => GetClientRequestUseCase(sl<ClientRequestsRepository>()),
      )
      ..registerLazySingleton(
        () => CreateDraftRequestUseCase(sl<ClientRequestsRepository>()),
      )
      ..registerLazySingleton(
        () => UpdateDraftRequestUseCase(sl<ClientRequestsRepository>()),
      )
      ..registerLazySingleton(
        () => SubmitRequestUseCase(sl<ClientRequestsRepository>()),
      )
      ..registerLazySingleton(
        () => CancelClientRequestUseCase(sl<ClientRequestsRepository>()),
      )
      ..registerLazySingleton(
        () => ConfirmClientRequestUseCase(sl<ClientRequestsRepository>()),
      )
      ..registerLazySingleton(
        () => DisputeClientRequestUseCase(sl<ClientRequestsRepository>()),
      )
      ..registerLazySingleton(
        () => AcceptOfferUseCase(sl<ClientRequestsRepository>()),
      )
      ..registerLazySingleton(
        () => RejectOfferUseCase(sl<ClientRequestsRepository>()),
      )
      ..registerLazySingleton(
        () => CounterOfferUseCase(sl<ClientRequestsRepository>()),
      )
      ..registerLazySingleton(
        () => BrowseCatalogueServicesUseCase(sl<CatalogueRepository>()),
      )
      ..registerLazySingleton(
        () => GetCatalogueCategoriesUseCase(sl<CatalogueRepository>()),
      )
      ..registerFactory(
        () => ClientRequestsListBloc(
          listRequests: sl<ListClientRequestsUseCase>(),
        ),
      )
      ..registerFactory(
        () => RequestDraftBloc(
          createDraft: sl<CreateDraftRequestUseCase>(),
          updateDraft: sl<UpdateDraftRequestUseCase>(),
          submitRequest: sl<SubmitRequestUseCase>(),
          getRequest: sl<GetClientRequestUseCase>(),
        ),
      );
  }
}
