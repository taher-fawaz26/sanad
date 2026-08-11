import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:document_flow/document_flow.dart';
import 'package:network/network.dart';
import 'package:sanad_provider/src/features/registration/src/data/datasources/media_remote_datasource.dart';
import 'package:sanad_provider/src/features/registration/src/data/repositories/registration_document_repository.dart';

/// GetIt instance name registration uses for every `document_flow` type it
/// registers. Required: `DocumentFlowRepository` and its use cases are
/// generic types — every feature implementing the shared flow registers its
/// own instance, and an unqualified registration would collide with another
/// feature's (e.g. `organization_settings`) registration of the same type.
const registrationDocumentFlowInstance = 'registration';

/// GetIt registrations for the registration feature.
abstract final class RegistrationDI {
  RegistrationDI._();

  static void init() {
    sl
      ..registerLazySingleton<MediaRemoteDataSource>(
        () => MediaRemoteDataSourceImpl(sl<SecureDioClient>()),
      )
      ..registerLazySingleton<DocumentFlowRepository>(
        () => RegistrationDocumentRepository(
          sl<MediaRemoteDataSource>(),
          sl<NetworkGuard>(),
          sl<SessionManager>(),
        ),
        instanceName: registrationDocumentFlowInstance,
      )
      ..registerLazySingleton(
        () => UploadMediaUseCase(
          sl<DocumentFlowRepository>(
            instanceName: registrationDocumentFlowInstance,
          ),
        ),
        instanceName: registrationDocumentFlowInstance,
      )
      ..registerLazySingleton(
        () => ExtractDocumentsUseCase(
          sl<DocumentFlowRepository>(
            instanceName: registrationDocumentFlowInstance,
          ),
        ),
        instanceName: registrationDocumentFlowInstance,
      )
      ..registerLazySingleton(
        () => SubmitDocumentsUseCase(
          sl<DocumentFlowRepository>(
            instanceName: registrationDocumentFlowInstance,
          ),
        ),
        instanceName: registrationDocumentFlowInstance,
      )
      ..registerLazySingleton(
        () => FetchDocumentsUseCase(
          sl<DocumentFlowRepository>(
            instanceName: registrationDocumentFlowInstance,
          ),
        ),
        instanceName: registrationDocumentFlowInstance,
      );
  }
}
