import 'package:core/core.dart';
import 'package:network/network.dart';
import 'package:services/src/data/datasources/catalog_remote_data_source.dart';
import 'package:services/src/data/datasources/provider_services_remote_data_source.dart';
import 'package:services/src/data/datasources/services_remote_data_source.dart';
import 'package:services/src/data/repositories/catalog_repository_impl.dart';
import 'package:services/src/data/repositories/categories_repository_impl.dart';
import 'package:services/src/data/repositories/provider_services_repository_impl.dart';
import 'package:services/src/data/repositories/service_requests_repository_impl.dart';
import 'package:services/src/domain/repositories/catalog_repository.dart';
import 'package:services/src/domain/repositories/categories_repository.dart';
import 'package:services/src/domain/repositories/provider_services_repository.dart';
import 'package:services/src/domain/repositories/service_requests_repository.dart';
import 'package:services/src/domain/usecases/browse_catalog_usecase.dart';
import 'package:services/src/domain/usecases/create_provider_service_usecase.dart';
import 'package:services/src/domain/usecases/create_service_request_usecase.dart';
import 'package:services/src/domain/usecases/delete_provider_service_image_usecase.dart';
import 'package:services/src/domain/usecases/delete_provider_service_usecase.dart';
import 'package:services/src/domain/usecases/get_categories_usecase.dart';
import 'package:services/src/domain/usecases/get_my_service_requests_usecase.dart';
import 'package:services/src/domain/usecases/get_provider_service_usecase.dart';
import 'package:services/src/domain/usecases/get_provider_services_overview_usecase.dart';
import 'package:services/src/domain/usecases/get_service_request_usecase.dart';
import 'package:services/src/domain/usecases/list_provider_services_usecase.dart';
import 'package:services/src/domain/usecases/set_primary_provider_service_image_usecase.dart';
import 'package:services/src/domain/usecases/set_provider_service_status_usecase.dart';
import 'package:services/src/domain/usecases/update_provider_service_description_usecase.dart';
import 'package:services/src/presentation/bloc/add_service/add_service_bloc.dart';
import 'package:services/src/presentation/bloc/edit_service/edit_service_bloc.dart';
import 'package:services/src/presentation/bloc/request_new_service/request_new_service_bloc.dart';
import 'package:services/src/presentation/bloc/service_action/service_action_bloc.dart';
import 'package:services/src/presentation/bloc/service_analytics/service_analytics_bloc.dart';
import 'package:services/src/presentation/bloc/service_requests_list/service_requests_list_bloc.dart';
import 'package:services/src/presentation/bloc/services_list/services_list_bloc.dart';

abstract final class ServicesDI {
  ServicesDI._();

  static void init() {
    sl
      // ─── Categories + service-requests (share ServicesRemoteDataSource). ──
      ..registerLazySingleton<ServicesRemoteDataSource>(
        () => ServicesRemoteDataSourceImpl(sl<BaseApiClient>()),
      )
      ..registerLazySingleton<CategoriesRepository>(
        () => CategoriesRepositoryImpl(sl<ServicesRemoteDataSource>()),
      )
      ..registerLazySingleton<ServiceRequestsRepository>(
        () => ServiceRequestsRepositoryImpl(sl<ServicesRemoteDataSource>()),
      )
      ..registerLazySingleton(
        () => GetCategoriesUseCase(sl<CategoriesRepository>()),
      )
      ..registerLazySingleton(
        () => CreateServiceRequestUseCase(sl<ServiceRequestsRepository>()),
      )
      ..registerLazySingleton(
        () => GetMyServiceRequestsUseCase(sl<ServiceRequestsRepository>()),
      )
      ..registerLazySingleton(
        () => GetServiceRequestUseCase(sl<ServiceRequestsRepository>()),
      )
      ..registerFactory(
        () => RequestNewServiceBloc(
          createServiceRequestUseCase: sl<CreateServiceRequestUseCase>(),
        ),
      )
      ..registerFactory(
        () => ServiceRequestsListBloc(
          getMyServiceRequestsUseCase: sl<GetMyServiceRequestsUseCase>(),
        ),
      )
      // ─── Catalog (read-only browse) + provider-services (CRUD, status,
      // overview, images). ──────────────────────────────────────────
      ..registerLazySingleton<CatalogRemoteDataSource>(
        () => CatalogRemoteDataSourceImpl(sl<BaseApiClient>()),
      )
      ..registerLazySingleton<ProviderServicesRemoteDataSource>(
        () => ProviderServicesRemoteDataSourceImpl(sl<BaseApiClient>()),
      )
      ..registerLazySingleton<CatalogRepository>(
        () => CatalogRepositoryImpl(sl<CatalogRemoteDataSource>()),
      )
      ..registerLazySingleton<ProviderServicesRepository>(
        () => ProviderServicesRepositoryImpl(
          sl<ProviderServicesRemoteDataSource>(),
        ),
      )
      ..registerLazySingleton(
        () => BrowseCatalogUseCase(sl<CatalogRepository>()),
      )
      ..registerLazySingleton(
        () => ListProviderServicesUseCase(sl<ProviderServicesRepository>()),
      )
      ..registerLazySingleton(
        () => GetProviderServiceUseCase(sl<ProviderServicesRepository>()),
      )
      ..registerLazySingleton(
        () => CreateProviderServiceUseCase(sl<ProviderServicesRepository>()),
      )
      ..registerLazySingleton(
        () => UpdateProviderServiceDescriptionUseCase(
          sl<ProviderServicesRepository>(),
        ),
      )
      ..registerLazySingleton(
        () => DeleteProviderServiceUseCase(sl<ProviderServicesRepository>()),
      )
      ..registerLazySingleton(
        () => SetProviderServiceStatusUseCase(
          sl<ProviderServicesRepository>(),
        ),
      )
      ..registerLazySingleton(
        () => GetProviderServicesOverviewUseCase(
          sl<ProviderServicesRepository>(),
        ),
      )
      ..registerLazySingleton(
        () => DeleteProviderServiceImageUseCase(
          sl<ProviderServicesRepository>(),
        ),
      )
      ..registerLazySingleton(
        () => SetPrimaryProviderServiceImageUseCase(
          sl<ProviderServicesRepository>(),
        ),
      )
      ..registerFactory(
        () => ServicesListBloc(
          listProviderServicesUseCase: sl<ListProviderServicesUseCase>(),
        ),
      )
      ..registerFactory(
        () => ServiceActionBloc(
          deleteProviderServiceUseCase: sl<DeleteProviderServiceUseCase>(),
          setProviderServiceStatusUseCase:
              sl<SetProviderServiceStatusUseCase>(),
        ),
      )
      ..registerFactory(
        () => ServiceAnalyticsBloc(
          getProviderServicesOverviewUseCase:
              sl<GetProviderServicesOverviewUseCase>(),
        ),
      )
      ..registerFactory(
        () => AddServiceBloc(
          createProviderServiceUseCase: sl<CreateProviderServiceUseCase>(),
        ),
      )
      ..registerFactory(
        () => EditServiceBloc(
          updateProviderServiceDescriptionUseCase:
              sl<UpdateProviderServiceDescriptionUseCase>(),
        ),
      );
  }
}
