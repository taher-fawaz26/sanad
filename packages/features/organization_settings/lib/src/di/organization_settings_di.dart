import 'package:core/core.dart';
import 'package:network/network.dart';
import 'package:organization_settings/src/data/datasources/organization_contact_remote_datasource.dart';
import 'package:organization_settings/src/data/datasources/organization_media_remote_datasource.dart';
import 'package:organization_settings/src/data/repositories/organization_contact_repository_impl.dart';
import 'package:organization_settings/src/data/repositories/organization_media_repository_impl.dart';
import 'package:organization_settings/src/domain/repositories/organization_contact_repository.dart';
import 'package:organization_settings/src/domain/repositories/organization_media_repository.dart';
import 'package:organization_settings/src/domain/usecases/get_organization_contact_usecase.dart';
import 'package:organization_settings/src/domain/usecases/remove_organization_media_usecase.dart';
import 'package:organization_settings/src/domain/usecases/request_email_otp_usecase.dart';
import 'package:organization_settings/src/domain/usecases/request_phone_otp_usecase.dart';
import 'package:organization_settings/src/domain/usecases/upload_organization_media_usecase.dart';
import 'package:organization_settings/src/domain/usecases/verify_email_otp_usecase.dart';
import 'package:organization_settings/src/domain/usecases/verify_phone_otp_usecase.dart';
import 'package:organization_settings/src/presentation/bloc/contact_information/contact_information_bloc.dart';
import 'package:organization_settings/src/presentation/bloc/identity_header/identity_header_bloc.dart';

/// Dependency registration for organization_settings.
///
/// Owns the identity-header upload stack (datasource → repository → use cases
/// → bloc). The generic `media` package is UI-only and registers nothing.
abstract final class OrganizationSettingsDI {
  OrganizationSettingsDI._();

  static void init() {
    sl
      ..registerLazySingleton<OrganizationMediaRemoteDataSource>(
        () => OrganizationMediaRemoteDataSourceImpl(sl<SecureDioClient>()),
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
      ..registerLazySingleton<OrganizationContactRemoteDataSource>(
        () => OrganizationContactRemoteDataSourceImpl(sl<BaseApiClient>()),
      )
      ..registerLazySingleton<OrganizationContactRepository>(
        () => OrganizationContactRepositoryImpl(
          sl<OrganizationContactRemoteDataSource>(),
          sl<NetworkGuard>(),
        ),
      )
      ..registerLazySingleton(
        () =>
            GetOrganizationContactUseCase(sl<OrganizationContactRepository>()),
      )
      ..registerLazySingleton(
        () => RequestPhoneOtpUseCase(sl<OrganizationContactRepository>()),
      )
      ..registerLazySingleton(
        () => VerifyPhoneOtpUseCase(sl<OrganizationContactRepository>()),
      )
      ..registerLazySingleton(
        () => RequestEmailOtpUseCase(sl<OrganizationContactRepository>()),
      )
      ..registerLazySingleton(
        () => VerifyEmailOtpUseCase(sl<OrganizationContactRepository>()),
      )
      ..registerFactory(
        () => ContactInformationBloc(
          getContact: sl<GetOrganizationContactUseCase>(),
        ),
      );
  }
}
