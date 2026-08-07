import 'package:core/core.dart';
import 'package:document_flow/document_flow.dart';
import 'package:network/network.dart';
import 'package:organization_settings/src/data/datasources/legal_data_remote_datasource.dart';
import 'package:organization_settings/src/data/datasources/media_upload_remote_datasource.dart';
import 'package:organization_settings/src/data/datasources/organization_media_remote_datasource.dart';
import 'package:organization_settings/src/data/datasources/organization_settings_remote_datasource.dart';
import 'package:organization_settings/src/data/repositories/organization_document_repository.dart';
import 'package:organization_settings/src/data/repositories/organization_media_repository_impl.dart';
import 'package:organization_settings/src/data/repositories/organization_settings_repository_impl.dart';
import 'package:organization_settings/src/domain/repositories/organization_media_repository.dart';
import 'package:organization_settings/src/domain/repositories/organization_settings_repository.dart';
import 'package:organization_settings/src/domain/usecases/get_organization_settings_usecase.dart';
import 'package:organization_settings/src/domain/usecases/remove_organization_media_usecase.dart';
import 'package:organization_settings/src/domain/usecases/upload_organization_media_usecase.dart';
import 'package:organization_settings/src/presentation/bloc/identity_header/identity_header_bloc.dart';
import 'package:organization_settings/src/presentation/bloc/organization_settings/organization_settings_bloc.dart';

/// GetIt instance name organization_settings uses for every `document_flow`
/// type it registers — `DocumentFlowRepository` and its use cases are
/// generic types shared with `registration`; an unqualified registration
/// would collide with registration's own instance of the same type.
const organizationDocumentFlowInstance = 'organization_settings';

/// Dependency registration for organization_settings.
///
/// Owns the identity-header upload stack (datasource → repository → use cases
/// → bloc). The generic `media` package is UI-only and registers nothing.
abstract final class OrganizationSettingsDI {
  OrganizationSettingsDI._();

  static void init() {
    sl
      ..registerLazySingleton<MediaUploadRemoteDataSource>(
        () => MediaUploadRemoteDataSourceImpl(sl<SecureDioClient>()),
      )
      ..registerLazySingleton<OrganizationMediaRemoteDataSource>(
        () => OrganizationMediaRemoteDataSourceImpl(
          sl<MediaUploadRemoteDataSource>(),
          sl<BaseApiClient>(),
        ),
      )
      ..registerLazySingleton<OrganizationMediaRepository>(
        () => OrganizationMediaRepositoryImpl(
          sl<OrganizationMediaRemoteDataSource>(),
          sl<NetworkGuard>(),
        ),
      )
      ..registerLazySingleton(
        () => UploadOrganizationMediaUseCase(sl<OrganizationMediaRepository>()),
      )
      ..registerLazySingleton(
        () => RemoveOrganizationMediaUseCase(sl<OrganizationMediaRepository>()),
      )
      ..registerFactory(
        () => IdentityHeaderBloc(
          uploadUseCase: sl<UploadOrganizationMediaUseCase>(),
          removeUseCase: sl<RemoveOrganizationMediaUseCase>(),
          repository: sl<OrganizationMediaRepository>(),
        ),
      )
      ..registerLazySingleton<OrganizationSettingsRemoteDataSource>(
        () => OrganizationSettingsRemoteDataSourceImpl(sl<BaseApiClient>()),
      )
      ..registerLazySingleton<OrganizationSettingsRepository>(
        () => OrganizationSettingsRepositoryImpl(
          sl<OrganizationSettingsRemoteDataSource>(),
          sl<NetworkGuard>(),
        ),
      )
      ..registerLazySingleton(
        () => GetOrganizationSettingsUseCase(
          sl<OrganizationSettingsRepository>(),
        ),
      )
      ..registerFactory(
        () => OrganizationSettingsBloc(
          getOrganizationSettings: sl<GetOrganizationSettingsUseCase>(),
        ),
      )
      ..registerLazySingleton<LegalDataRemoteDataSource>(
        () => LegalDataRemoteDataSourceImpl(
          sl<BaseApiClient>(),
          sl<MediaUploadRemoteDataSource>(),
        ),
      )
      ..registerLazySingleton<DocumentFlowRepository>(
        () => OrganizationDocumentRepository(
          sl<LegalDataRemoteDataSource>(),
          sl<NetworkGuard>(),
        ),
        instanceName: organizationDocumentFlowInstance,
      )
      ..registerLazySingleton(
        () => UploadMediaUseCase(
          sl<DocumentFlowRepository>(
            instanceName: organizationDocumentFlowInstance,
          ),
        ),
        instanceName: organizationDocumentFlowInstance,
      )
      ..registerLazySingleton(
        () => ExtractDocumentsUseCase(
          sl<DocumentFlowRepository>(
            instanceName: organizationDocumentFlowInstance,
          ),
        ),
        instanceName: organizationDocumentFlowInstance,
      )
      ..registerLazySingleton(
        () => SubmitDocumentsUseCase(
          sl<DocumentFlowRepository>(
            instanceName: organizationDocumentFlowInstance,
          ),
        ),
        instanceName: organizationDocumentFlowInstance,
      )
      ..registerLazySingleton(
        () => FetchDocumentsUseCase(
          sl<DocumentFlowRepository>(
            instanceName: organizationDocumentFlowInstance,
          ),
        ),
        instanceName: organizationDocumentFlowInstance,
      );
  }
}
