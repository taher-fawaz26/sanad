import 'package:app_logger/app_logger.dart';
import 'package:asset_picker/asset_picker.dart';
import 'package:auth/auth.dart';
import 'package:branches/branches.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:forgot_password/forgot_password.dart';
import 'package:invitation/invitation.dart';
import 'package:localization/localization.dart';
import 'package:maps/maps.dart';
import 'package:network/network.dart';
import 'package:otp/otp.dart';
import 'package:permissions/permissions.dart';
import 'package:registration/registration.dart';
import 'package:sanad_provider/src/config/app_config.dart';
import 'package:services/services.dart';
import 'package:storage/storage.dart';
import 'package:workers/workers.dart';

late final ModuleRegistry moduleRegistry;

/// Registers all application-level dependencies with the service locator.
Future<void> configureDependencies() async {
  // ── Storage ──────────────────────────────────────────────────────────────
  sl
    ..registerLazySingleton(() => const FlutterSecureStorage())
    ..registerLazySingleton<HiveEncryptionKeyManager>(
      () => HiveEncryptionKeyManager(sl<FlutterSecureStorage>()),
    )
    ..registerLazySingleton<HiveLocalStorage>(
      () => HiveLocalStorage(
        encryptionKeyManager: sl<HiveEncryptionKeyManager>(),
      ),
    )
    ..registerLazySingleton<TokenStorage>(
      () => TokenStorageImpl(sl<FlutterSecureStorage>()),
    )
    // ── Localization & Theme ─────────────────────────────────────────────────
    ..registerLazySingleton(TranslateBloc.new)
    ..registerLazySingleton(ThemeBloc.new)
    // ── Auth status ──────────────────────────────────────────────────────────
    ..registerLazySingleton(AuthStatusNotifier.new);

  // ── Network stack (Dio, interceptors, token manager, connectivity) ───────
  await NetworkDI.init(
    networkConfig: AppConfig.network,
    logger: appLogger,
    resolveLanguageCode: () => sl<TranslateBloc>().state.languageCode,
    onUnauthorized: () =>
        sl<AuthStatusNotifier>().update(AuthStatus.unauthenticated),
  );

  // ── Permissions (registers PermissionService, config, theme, provider) ───
  PermissionsDI.init();

  sl
    ..registerLazySingleton<LocationService>(
      () => LocationServiceImpl(sl<PermissionService>()),
    )
    ..registerLazySingleton<GeocodingService>(
      () => const GeocodingServiceImpl(),
    );

  // ── Feature modules ────────────────────────────────────────────────────────
  moduleRegistry = ModuleRegistry([
    MapsModule(
      config: const MapsConfig(
        placesApiKey: String.fromEnvironment('MAPS_API_KEY'),
      ),
    ),
    AuthModule(),
    OtpModule(),
    ForgotPasswordModule(),
    BranchesModule(),
    ServicesModule(),
    WorkersModule(),
    InvitationModule(),
    RegistrationModule(),
    AssetPickerModule(),
  ]);
  await moduleRegistry.initAll();

  appLogger.i('[AppDI] Dependency injection configured for sanad_provider');
}
