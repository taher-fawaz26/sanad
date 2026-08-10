import 'package:account_settings/account_settings.dart';
import 'package:app_logger/app_logger.dart';
import 'package:asset_picker/asset_picker.dart';
import 'package:auth/auth.dart';
import 'package:branches/branches.dart';
import 'package:contact_verification/contact_verification.dart';
import 'package:core/core.dart';
import 'package:deep_linking/deep_linking.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:invitation/invitation.dart';
import 'package:localization/localization.dart';
import 'package:maps/maps.dart';
import 'package:media_upload/media_upload.dart';
import 'package:network/network.dart';
import 'package:organization_settings/organization_settings.dart';
import 'package:permissions/permissions.dart';
import 'package:provider_rbac/provider_rbac.dart';
import 'package:registration/registration.dart';
import 'package:sanad_provider/src/config/app_config.dart';
import 'package:sanad_provider/src/routing/provider_navigator.dart';
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
    onUnauthorized: () {
      // 401-refresh-failure hand-off: fire-and-forget a full session wipe
      // (tokens are already cleared by the interceptor; this also drops the
      // Hive session snapshot and in-memory cache) then flips the auth-status
      // notifier so the router redirects to Login.
      sl<SessionManager>().clear().ignore();
    },
  );

  // ── Permissions (registers PermissionService, config, theme, provider) ───
  PermissionsDI.init();

  // ── Media upload (shared multipart-upload pipeline; no FeatureModule) ────
  MediaUploadDI.init();

  // ── Deep linking (OS-level incoming URI → GoRouter location) ─────────────
  DeepLinkingDI.init(config: AppConfig.deepLinkConfig);

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
    ContactVerificationModule(),
    AccountSettingsModule(),
    OrganizationSettingsModule(),
    BranchesModule(),
    ServicesModule(),
    WorkersModule(),
    ProviderRbacModule(),
    InvitationModule(),
    RegistrationModule(),
    AssetPickerModule(
      config: AssetPickerConfig(
        scannerNavigatorKey: providerRootNavigatorKey,
        documentScannerConfig: const DocumentScannerConfig(
          requireBothSides: false,
          primaryColor: Color(0xFF26A68C),
          showInstructionText: true,
          screenTitle: 'Scan Emirates ID',
          frontSideInstruction: 'Place the front inside the frame',
          backSideInstruction: 'Place the back inside the frame',
          frontSideTitle: 'Front Side',
          backSideTitle: 'Back Side',
          retakeButtonText: 'Retake Front Side',
          nextButtonText: 'Scan Back Side',
          previousButtonText: 'Retake Front Side',
          saveButtonText: 'Continue',
        ),
      ),
    ),
  ]);
  await moduleRegistry.initAll();
}
