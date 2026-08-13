import 'package:auth/auth.dart' show SessionManager;
import 'package:core/core.dart';
import 'package:document_flow/document_flow.dart';
import 'package:network/network.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/datasources/legal_data_remote_datasource.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/datasources/media_upload_remote_datasource.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/datasources/organization_media_remote_datasource.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/datasources/organization_settings_cache_datasource.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/datasources/organization_settings_remote_datasource.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/datasources/provider_overview_remote_datasource.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/datasources/working_hours_remote_datasource.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/repositories/organization_document_repository.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/repositories/organization_media_repository_impl.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/repositories/organization_settings_repository_impl.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/repositories/provider_overview_repository_impl.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/repositories/working_hours_repository_impl.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/repositories/organization_media_repository.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/repositories/organization_settings_repository.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/repositories/provider_overview_repository.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/repositories/working_hours_repository.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/usecases/get_organization_settings_usecase.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/usecases/get_provider_completion_usecase.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/usecases/get_provider_overview_usecase.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/usecases/get_working_hours_usecase.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/usecases/remove_organization_media_usecase.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/usecases/update_service_provider_settings_usecase.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/usecases/update_working_hours_usecase.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/usecases/upload_organization_media_usecase.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/bloc/identity_header/identity_header_bloc.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/bloc/organization_settings/organization_settings_bloc.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/bloc/provider_completion/provider_completion_bloc.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/bloc/provider_overview/provider_overview_bloc.dart';
import 'package:services/services.dart';
import 'package:storage/storage.dart';

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
      ..registerLazySingleton<LegalDataRemoteDataSource>(
        () => LegalDataRemoteDataSourceImpl(
          sl<BaseApiClient>(),
          sl<MediaUploadRemoteDataSource>(),
        ),
      )
      ..registerLazySingleton<OrganizationSettingsCacheDataSource>(
        () => OrganizationSettingsCacheDataSourceImpl(sl<HiveLocalStorage>()),
      )
      ..registerLazySingleton<OrganizationSettingsRepository>(
        () => OrganizationSettingsRepositoryImpl(
          sl<OrganizationSettingsRemoteDataSource>(),
          sl<LegalDataRemoteDataSource>(),
          sl<NetworkGuard>(),
          sl<OrganizationSettingsCacheDataSource>(),
          sl<SessionManager>(),
        ),
      )
      ..registerLazySingleton(
        () => GetOrganizationSettingsUseCase(
          sl<OrganizationSettingsRepository>(),
        ),
      )
      ..registerLazySingleton(
        () => UpdateServiceProviderSettingsUseCase(
          sl<OrganizationSettingsRepository>(),
        ),
      )
      ..registerLazySingleton(
        () =>
            GetProviderCompletionUseCase(sl<OrganizationSettingsRepository>()),
      )
      ..registerLazySingleton<WorkingHoursRemoteDataSource>(
        () => WorkingHoursRemoteDataSourceImpl(sl<BaseApiClient>()),
      )
      ..registerLazySingleton<WorkingHoursRepository>(
        () => WorkingHoursRepositoryImpl(
          sl<WorkingHoursRemoteDataSource>(),
          sl<NetworkGuard>(),
          sl<OrganizationSettingsCacheDataSource>(),
          sl<SessionManager>(),
        ),
      )
      ..registerLazySingleton(
        () => GetWorkingHoursUseCase(sl<WorkingHoursRepository>()),
      )
      ..registerLazySingleton(
        () => UpdateWorkingHoursUseCase(sl<WorkingHoursRepository>()),
      )
      ..registerLazySingleton<ProviderOverviewRemoteDataSource>(
        () => ProviderOverviewRemoteDataSourceImpl(sl<BaseApiClient>()),
      )
      ..registerLazySingleton<ProviderOverviewRepository>(
        () => ProviderOverviewRepositoryImpl(
          sl<ProviderOverviewRemoteDataSource>(),
          sl<NetworkGuard>(),
        ),
      )
      ..registerLazySingleton(
        () => GetProviderOverviewUseCase(sl<ProviderOverviewRepository>()),
      )
      ..registerFactory(
        () => OrganizationSettingsBloc(
          getOrganizationSettings: sl<GetOrganizationSettingsUseCase>(),
          updateServiceProviderSettings:
              sl<UpdateServiceProviderSettingsUseCase>(),
          getCompletion: sl<GetProviderCompletionUseCase>(),
          getWorkingHours: sl<GetWorkingHoursUseCase>(),
          updateWorkingHours: sl<UpdateWorkingHoursUseCase>(),
          getCategories: sl<GetCategoriesUseCase>(),
          organizationSettingsRepository: sl<OrganizationSettingsRepository>(),
          workingHoursRepository: sl<WorkingHoursRepository>(),
        ),
      )
      ..registerFactory(
        () => ProviderOverviewBloc(
          getOverview: sl<GetProviderOverviewUseCase>(),
        ),
      )
      ..registerFactory(
        () => ProviderCompletionBloc(
          getCompletion: sl<GetProviderCompletionUseCase>(),
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
