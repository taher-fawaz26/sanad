import 'package:core/core.dart';
import 'package:network/network.dart';
import 'package:registration/src/data/datasources/media_remote_datasource.dart';
import 'package:registration/src/data/repositories/media_repository_impl.dart';
import 'package:registration/src/domain/repositories/media_repository.dart';
import 'package:registration/src/domain/usecases/upload_single_media_usecase.dart';

/// GetIt registrations for the registration feature.
abstract final class RegistrationDI {
  RegistrationDI._();

  static void init() {
    sl
      ..registerLazySingleton<MediaRemoteDataSource>(
        () => MediaRemoteDataSourceImpl(sl<SecureDioClient>()),
      )
      ..registerLazySingleton<MediaRepository>(
        () => MediaRepositoryImpl(
          sl<MediaRemoteDataSource>(),
          sl<NetworkGuard>(),
        ),
      )
      ..registerLazySingleton(
        () => UploadSingleMediaUseCase(sl<MediaRepository>()),
      );
  }
}
