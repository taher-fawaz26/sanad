import 'package:account_settings/src/data/datasources/account_deletion_remote_datasource.dart';
import 'package:account_settings/src/data/datasources/account_settings_remote_datasource.dart';
import 'package:account_settings/src/data/repositories/account_deletion_repository_impl.dart';
import 'package:account_settings/src/data/repositories/account_settings_repository_impl.dart';
import 'package:account_settings/src/domain/repositories/account_deletion_repository.dart';
import 'package:account_settings/src/domain/repositories/account_settings_repository.dart';
import 'package:account_settings/src/domain/usecases/cancel_deletion_usecase.dart';
import 'package:account_settings/src/domain/usecases/get_deletion_eligibility_usecase.dart';
import 'package:account_settings/src/domain/usecases/get_deletion_resend_info_usecase.dart';
import 'package:account_settings/src/domain/usecases/get_deletion_status_usecase.dart';
import 'package:account_settings/src/domain/usecases/refresh_account_profile_usecase.dart';
import 'package:account_settings/src/domain/usecases/resend_deletion_otp_usecase.dart';
import 'package:account_settings/src/domain/usecases/start_account_deletion_usecase.dart';
import 'package:account_settings/src/domain/usecases/update_account_settings_usecase.dart';
import 'package:account_settings/src/domain/usecases/verify_deletion_otp_usecase.dart';
import 'package:account_settings/src/presentation/bloc/account_deletion/account_deletion_bloc.dart';
import 'package:account_settings/src/presentation/bloc/account_settings/account_settings_bloc.dart';
import 'package:auth/auth.dart'
    show AuthLogoutUseCase, GetCurrentUserUseCase, SessionManager;
import 'package:core/core.dart';
import 'package:network/network.dart';

/// Dependency registration for account_settings.
abstract final class AccountSettingsDI {
  AccountSettingsDI._();

  /// Registers account_settings dependencies with GetIt.
  static void init() {
    sl
      ..registerLazySingleton<AccountSettingsRemoteDataSource>(
        () => AccountSettingsRemoteDataSourceImpl(sl<BaseApiClient>()),
      )
      ..registerLazySingleton<AccountSettingsRepository>(
        () => AccountSettingsRepositoryImpl(
          sl<AccountSettingsRemoteDataSource>(),
          sl<NetworkGuard>(),
        ),
      )
      ..registerLazySingleton(
        () => UpdateAccountSettingsUseCase(sl<AccountSettingsRepository>()),
      )
      ..registerLazySingleton(
        () => RefreshAccountProfileUseCase(
          sl<GetCurrentUserUseCase>(),
          sl<AccountSettingsRepository>(),
        ),
      )
      ..registerFactory(
        () => AccountSettingsBloc(
          updateAccountSettings: sl<UpdateAccountSettingsUseCase>(),
          refreshAccountProfile: sl<RefreshAccountProfileUseCase>(),
          sessionManager: sl<SessionManager>(),
        ),
      )
      ..registerLazySingleton<AccountDeletionRemoteDataSource>(
        () => AccountDeletionRemoteDataSourceImpl(sl<BaseApiClient>()),
      )
      ..registerLazySingleton<AccountDeletionRepository>(
        () => AccountDeletionRepositoryImpl(
          sl<AccountDeletionRemoteDataSource>(),
          sl<NetworkGuard>(),
        ),
      )
      ..registerLazySingleton(
        () => GetDeletionEligibilityUseCase(sl<AccountDeletionRepository>()),
      )
      ..registerLazySingleton(
        () => StartAccountDeletionUseCase(sl<AccountDeletionRepository>()),
      )
      ..registerLazySingleton(
        () => VerifyDeletionOtpUseCase(sl<AccountDeletionRepository>()),
      )
      ..registerLazySingleton(
        () => ResendDeletionOtpUseCase(sl<AccountDeletionRepository>()),
      )
      ..registerLazySingleton(
        () => GetDeletionResendInfoUseCase(sl<AccountDeletionRepository>()),
      )
      ..registerLazySingleton(
        () => GetDeletionStatusUseCase(sl<AccountDeletionRepository>()),
      )
      ..registerLazySingleton(
        () => CancelDeletionUseCase(sl<AccountDeletionRepository>()),
      )
      ..registerFactory(
        () => AccountDeletionBloc(
          getEligibility: sl<GetDeletionEligibilityUseCase>(),
          startDeletion: sl<StartAccountDeletionUseCase>(),
          getStatus: sl<GetDeletionStatusUseCase>(),
          cancelDeletion: sl<CancelDeletionUseCase>(),
          getCurrentUser: sl<GetCurrentUserUseCase>(),
          sessionManager: sl<SessionManager>(),
        ),
      );
  }
}
