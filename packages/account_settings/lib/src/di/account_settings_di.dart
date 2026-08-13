import 'package:account_settings/src/data/datasources/account_settings_remote_datasource.dart';
import 'package:account_settings/src/data/repositories/account_settings_repository_impl.dart';
import 'package:account_settings/src/domain/repositories/account_settings_repository.dart';
import 'package:account_settings/src/domain/usecases/refresh_account_profile_usecase.dart';
import 'package:account_settings/src/domain/usecases/update_account_settings_usecase.dart';
import 'package:account_settings/src/presentation/bloc/account_settings/account_settings_bloc.dart';
import 'package:auth/auth.dart' show GetCurrentUserUseCase, SessionManager;
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
      );
  }
}
