import 'package:core/core.dart';
import 'package:network/network.dart';
import 'package:services/src/data/datasources/service_remote_data_source.dart';
import 'package:services/src/data/datasources/services_remote_data_source.dart';
import 'package:services/src/data/repositories/categories_repository_impl.dart';
import 'package:services/src/data/repositories/service_repository_impl.dart';
import 'package:services/src/data/repositories/service_requests_repository_impl.dart';
import 'package:services/src/data/repositories/services_repository_impl.dart';
import 'package:services/src/domain/repositories/categories_repository.dart';
import 'package:services/src/domain/repositories/service_repository.dart';
import 'package:services/src/domain/repositories/service_requests_repository.dart';
import 'package:services/src/domain/repositories/services_repository.dart';
import 'package:services/src/domain/usecases/create_service_request_usecase.dart';
import 'package:services/src/domain/usecases/create_service_usecase.dart';
import 'package:services/src/domain/usecases/delete_service_usecase.dart';
import 'package:services/src/domain/usecases/get_categories_usecase.dart';
import 'package:services/src/domain/usecases/get_my_service_requests_usecase.dart';
import 'package:services/src/domain/usecases/get_service_analytics_usecase.dart';
import 'package:services/src/domain/usecases/get_service_usecase.dart';
import 'package:services/src/domain/usecases/get_services_list_usecase.dart';
import 'package:services/src/domain/usecases/get_services_usecase.dart';
import 'package:services/src/domain/usecases/update_service_status_usecase.dart';
import 'package:services/src/domain/usecases/update_service_usecase.dart';
import 'package:services/src/presentation/bloc/add_service/add_service_bloc.dart';
import 'package:services/src/presentation/bloc/request_new_service/request_new_service_bloc.dart';
import 'package:services/src/presentation/bloc/service_action/service_action_bloc.dart';
import 'package:services/src/presentation/bloc/service_analytics/service_analytics_bloc.dart';
import 'package:services/src/presentation/bloc/service_requests_list/service_requests_list_bloc.dart';
import 'package:services/src/presentation/bloc/services_list/services_list_bloc.dart';

abstract final class ServicesDI {
  ServicesDI._();

  static void init() {
    sl
      // ─── Pre-existing: branch-service-assignment catalog (unrelated,
      // untouched — see `service_api_paths.dart` for why it's kept separate
      // from the real services CRUD surface registered below). ───────────
      ..registerLazySingleton<ServiceRemoteDataSource>(
        () => ServiceRemoteDataSourceImpl(sl<BaseApiClient>()),
      )
      ..registerLazySingleton<ServiceRepository>(
        () => ServiceRepositoryImpl(sl<ServiceRemoteDataSource>()),
      )
      ..registerLazySingleton(
        () => GetServicesUseCase(sl<ServiceRepository>()),
      )
      // ─── Real backend integration: categories / services / analytics /
      // service-requests. ──────────────────────────────────────────────
      ..registerLazySingleton<ServicesRemoteDataSource>(
        () => ServicesRemoteDataSourceImpl(sl<BaseApiClient>()),
      )
      ..registerLazySingleton<CategoriesRepository>(
        () => CategoriesRepositoryImpl(sl<ServicesRemoteDataSource>()),
      )
      ..registerLazySingleton<ServicesRepository>(
        () => ServicesRepositoryImpl(sl<ServicesRemoteDataSource>()),
      )
      ..registerLazySingleton<ServiceRequestsRepository>(
        () => ServiceRequestsRepositoryImpl(sl<ServicesRemoteDataSource>()),
      )
      ..registerLazySingleton(
        () => GetCategoriesUseCase(sl<CategoriesRepository>()),
      )
      ..registerLazySingleton(
        () => CreateServiceUseCase(sl<ServicesRepository>()),
      )
      ..registerLazySingleton(
        () => GetServicesListUseCase(sl<ServicesRepository>()),
      )
      ..registerLazySingleton(() => GetServiceUseCase(sl<ServicesRepository>()))
      ..registerLazySingleton(
        () => UpdateServiceUseCase(sl<ServicesRepository>()),
      )
      ..registerLazySingleton(
        () => DeleteServiceUseCase(sl<ServicesRepository>()),
      )
      ..registerLazySingleton(
        () => UpdateServiceStatusUseCase(sl<ServicesRepository>()),
      )
      ..registerLazySingleton(
        () => GetServiceAnalyticsUseCase(sl<ServicesRepository>()),
      )
      ..registerLazySingleton(
        () => CreateServiceRequestUseCase(sl<ServiceRequestsRepository>()),
      )
      ..registerLazySingleton(
        () => GetMyServiceRequestsUseCase(sl<ServiceRequestsRepository>()),
      )
      ..registerFactory(
        () => ServicesListBloc(
          getServicesListUseCase: sl<GetServicesListUseCase>(),
        ),
      )
      ..registerFactory(
        () => ServiceActionBloc(
          deleteServiceUseCase: sl<DeleteServiceUseCase>(),
          updateServiceStatusUseCase: sl<UpdateServiceStatusUseCase>(),
        ),
      )
      ..registerFactory(
        () => ServiceAnalyticsBloc(
          getServiceAnalyticsUseCase: sl<GetServiceAnalyticsUseCase>(),
        ),
      )
      ..registerFactory(
        () => AddServiceBloc(createServiceUseCase: sl<CreateServiceUseCase>()),
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
      );
  }
}
