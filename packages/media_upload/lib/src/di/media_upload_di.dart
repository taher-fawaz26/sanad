import 'package:core/core.dart';
import 'package:media_upload/src/data/datasources/media_upload_remote_datasource.dart';
import 'package:media_upload/src/data/repositories/media_upload_repository_impl.dart';
import 'package:media_upload/src/domain/entities/media_upload_config.dart';
import 'package:media_upload/src/domain/repositories/media_upload_repository.dart';
import 'package:media_upload/src/presentation/bloc/media_upload_bloc.dart';
import 'package:network/network.dart';

/// Dependency registration for the shared media-upload pipeline.
///
/// Registers exactly one `MediaUploadRemoteDataSource`/`MediaUploadRepository`
/// pair for the whole app — every feature bloc/usecase built on top shares
/// it rather than re-registering its own multipart-upload stack.
abstract final class MediaUploadDI {
  MediaUploadDI._();

  static void init() {
    sl
      ..registerLazySingleton<MediaUploadRemoteDataSource>(
        () => MediaUploadRemoteDataSourceImpl(sl<SecureDioClient>()),
      )
      ..registerLazySingleton<MediaUploadRepository>(
        () => MediaUploadRepositoryImpl(sl<MediaUploadRemoteDataSource>()),
      )
      ..registerFactoryParam<MediaUploadBloc, MediaUploadConfig, void>(
        (config, _) => MediaUploadBloc(
          repository: sl<MediaUploadRepository>(),
          config: config,
        ),
      );
  }
}
