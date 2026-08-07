import 'package:contact_verification/src/data/datasources/contact_verification_remote_datasource.dart';
import 'package:contact_verification/src/data/repositories/contact_verification_repository_impl.dart';
import 'package:contact_verification/src/domain/repositories/contact_verification_repository.dart';
import 'package:contact_verification/src/domain/usecases/get_resend_info_usecase.dart';
import 'package:contact_verification/src/domain/usecases/request_verification_usecase.dart';
import 'package:contact_verification/src/domain/usecases/resend_verification_usecase.dart';
import 'package:contact_verification/src/domain/usecases/verify_contact_usecase.dart';
import 'package:core/core.dart';
import 'package:network/network.dart';

abstract final class ContactVerificationDI {
  ContactVerificationDI._();

  static void init() {
    sl
      ..registerLazySingleton<ContactVerificationRemoteDataSource>(
        () => ContactVerificationRemoteDataSourceImpl(sl<BaseApiClient>()),
      )
      ..registerLazySingleton<ContactVerificationRepository>(
        () => ContactVerificationRepositoryImpl(
          sl<ContactVerificationRemoteDataSource>(),
        ),
      )
      ..registerLazySingleton(
        () => RequestVerificationUseCase(sl<ContactVerificationRepository>()),
      )
      ..registerLazySingleton(
        () => ResendVerificationUseCase(sl<ContactVerificationRepository>()),
      )
      ..registerLazySingleton(
        () => GetResendInfoUseCase(sl<ContactVerificationRepository>()),
      )
      ..registerLazySingleton(
        () => VerifyContactUseCase(sl<ContactVerificationRepository>()),
      );
  }
}
