import 'package:account_settings/account_settings.dart';
import 'package:activity_logs/activity_logs.dart';
import 'package:app_logger/app_logger.dart';
import 'package:asset_picker/asset_picker.dart';
import 'package:auth/auth.dart';
import 'package:branches/branches.dart';
import 'package:config/config.dart';
import 'package:contact_verification/contact_verification.dart';
import 'package:core/core.dart';
import 'package:deep_linking/deep_linking.dart';
import 'package:design_system/design_system.dart';
import 'package:device/device.dart';
import 'package:document_validation/document_validation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sanad_provider/src/features/home/home.dart';
import 'package:sanad_provider/src/features/invitation/invitation.dart';
import 'package:localization/localization.dart';
import 'package:maps/maps.dart';
import 'package:media_upload/media_upload.dart';
import 'package:network/network.dart';
import 'package:notifications/notifications.dart';
import 'package:sanad_provider/src/features/organization_settings/organization_settings.dart';
import 'package:permissions/permissions.dart';
import 'package:provider_rbac/provider_rbac.dart';
import 'package:sanad_provider/src/features/registration/registration.dart';
import 'package:sanad_provider/src/config/app_config.dart';
import 'package:sanad_provider/src/features/requests/requests.dart';
import 'package:sanad_provider/src/notifications/provider_notification_navigator.dart';
import 'package:sanad_provider/src/routing/provider_navigator.dart';
import 'package:services/services.dart';
import 'package:storage/storage.dart';
import 'package:text_optimization/text_optimization.dart';
import 'package:workers/workers.dart';

late final ModuleRegistry moduleRegistry;

/// Registers all application-level dependencies with the service locator.
/// [initialLanguage] seeds [TranslateBloc] only when it has no persisted
/// record — a stored choice always wins. See `LegacyLocalePreference`.
Future<void> configureDependencies({
  AppLanguage initialLanguage = AppLanguage.defaultLanguage,
}) async {
  // ── Build-time feature flags ─────────────────────────────────────────────
  sl.registerLazySingleton<FeatureFlags>(() => AppConfig.featureFlags);

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
    // Keychain/Keystore-backed key/value store. Used for security-sensitive
    // local preferences that must not live in the plaintext Hive default box
    // — currently the app-lock (biometric unlock) preference.
    ..registerLazySingleton<SecureLocalStorage>(
      () => SecureLocalStorage(sl<FlutterSecureStorage>()),
    )
    // ── Localization & Theme ─────────────────────────────────────────────────
    ..registerLazySingleton(() => TranslateBloc(fallback: initialLanguage))
    ..registerLazySingleton(ThemeBloc.new)
    // ── Auth status ──────────────────────────────────────────────────────────
    ..registerLazySingleton(AuthStatusNotifier.new)
    // Holds the live GoRouter so a notification tap has somewhere to go. The
    // root widget attaches it once the router exists.
    ..registerLazySingleton(ProviderNotificationNavigator.new);

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

  // ── Shared "Enhance with AI" text-optimization flow (SAN-578) ────────────
  TextOptimizationDI.init();

  // ── Permissions (registers PermissionService, config, theme, provider) ───
  PermissionsDI.init();

  // ── Media upload (shared multipart-upload pipeline; no FeatureModule) ────
  MediaUploadDI.init();

  // ── Activity Logs (GET /activity-logs; consumers are Worker Details' and
  // Home's "Recent Activity" sections, each owning its own bloc — no
  // routes, so no FeatureModule needed) ────────────────────────────────────
  ActivityLogsDI.init();

  // ── Pre-upload document-type validation (Emirates ID scan / Trade
  // License OCR gate); no FeatureModule — a `DocumentTypeValidator` used
  // directly by every `DocumentFlowBloc` instance. ─────────────────────────
  DocumentValidationDI.init();

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
    // Device capability gateway (biometrics, connectivity, clipboard, share,
    // device/app info). Registered first: it declares no dependencies and
    // other modules resolve its services lazily.
    DeviceModule(),
    MapsModule(
      config: const MapsConfig(
        placesApiKey: String.fromEnvironment('MAPS_API_KEY'),
      ),
    ),
    AuthModule(
      // Session-boundary hook (RBAC Phase 7A): every module's dispose() runs
      // whenever a session begins or ends, so per-session in-memory state
      // cannot survive a logout→login (or owner→worker) transition. Safe to
      // reference `moduleRegistry` here — this closure only runs long after
      // the assignment below completes.
      onSessionBoundary: () => moduleRegistry.disposeAll(),
      // Push registration is an upsert, not a setup step: it runs after every
      // login and on every launch that restores a session.
      onSessionStarted: () =>
          sl<PushRegistrationCoordinator>().syncRegistration().ignore(),
      // Runs while the access token is still live. Without it the signed-out
      // handset keeps receiving the next user's notifications — tokens belong
      // to devices, not users.
      onBeforeSessionEnd: () => sl<PushRegistrationCoordinator>().unregister(),
    ),
    ContactVerificationModule(),
    AccountSettingsModule(),
    HomeModule(),
    OrganizationSettingsModule(),
    BranchesModule(),
    ServicesModule(),
    WorkersModule(),
    ProviderRbacModule(),
    ProviderRequestsModule(),
    // The single owner of push registration and notification routing for this
    // app. Registered after AuthModule so the session exists by the time its
    // initialize() runs.
    NotificationsModule(
      resolveNavigator: () => sl<ProviderNotificationNavigator>(),
    ),
    InvitationModule(),
    RegistrationModule(),
    AssetPickerModule(
      config: AssetPickerConfig(
        scannerNavigatorKey: providerRootNavigatorKey,
        documentScannerConfig: const DocumentScannerConfig(
          primaryColor: Color(0xFF26A68C),
          showInstructionText: true,
          saveButtonText: 'Continue',
        ),
      ),
    ),
  ]);
  await moduleRegistry.initAll();
}
