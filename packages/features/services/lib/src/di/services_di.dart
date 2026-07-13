import 'package:core/core.dart';
import 'package:network/network.dart';
import 'package:services/src/data/datasources/service_remote_data_source.dart';
import 'package:services/src/data/repositories/service_repository_impl.dart';
import 'package:services/src/domain/repositories/service_repository.dart';
import 'package:services/src/domain/usecases/get_services_usecase.dart';

abstract final class ServicesDI {
  ServicesDI._();

  static void init() {
    sl
      ..registerLazySingleton<ServiceRemoteDataSource>(
        () => ServiceRemoteDataSourceImpl(sl<BaseApiClient>()),
      )
      ..registerLazySingleton<ServiceRepository>(
        () => ServiceRepositoryImpl(sl<ServiceRemoteDataSource>()),
      )
      ..registerLazySingleton(
        () => GetServicesUseCase(sl<ServiceRepository>()),
      );
  }
}
