import 'package:account_settings/account_settings.dart';
import 'package:app_logger/app_logger.dart';
import 'package:asset_picker/asset_picker.dart';
import 'package:auth/auth.dart';
import 'package:config/config.dart';
import 'package:contact_verification/contact_verification.dart';
import 'package:core/core.dart';
import 'package:deep_linking/deep_linking.dart';
import 'package:design_system/design_system.dart';
import 'package:device/device.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:localization/localization.dart';
import 'package:maps/maps.dart';
import 'package:media_upload/media_upload.dart';
import 'package:network/network.dart';
import 'package:notifications/notifications.dart';
import 'package:permissions/permissions.dart';
import 'package:sanad_client/src/config/app_config.dart';
import 'package:sanad_client/src/features/ai_chat/src/module/ai_chat_module.dart';
import 'package:sanad_client/src/features/client_requests/client_requests.dart';
import 'package:sanad_client/src/notifications/client_notification_navigator.dart';
import 'package:storage/storage.dart';

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
    ..registerLazySingleton(ClientNotificationNavigator.new);

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

  // ── Media upload (shared multipart pipeline) ─────────────────────────────
  // After `NetworkDI.init`, which registers the `SecureDioClient` this
  // resolves. One repository for the whole app; the AI chat's attachment
  // uploader is built on top of it rather than owning a second upload stack.
  MediaUploadDI.init();

  // ── Deep linking (OS-level incoming URI → GoRouter location) ─────────────
  DeepLinkingDI.init(config: AppConfig.deepLinkConfig);

  // ── Platform services `MapsDI` resolves but does not own ─────────────────
  // `MapsDI.init` wires repositories on top of these two, so the app that
  // registers `MapsModule` must supply them — exactly as `sanad_provider`
  // does. `MapsDI.init` resolves both lazily, so a missing registration only
  // surfaces as `GetIt: GeocodingService is not registered` at the moment a
  // map is first opened — never at startup.
  // `LocationServiceImpl` resolves `PermissionService` lazily, so it is safe
  // to register here, ahead of `PermissionsModule`.
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
    // Runtime permission gateway. Registered before anything that asks for a
    // capability: `Permissions` resolves `PermissionService` from `sl`, so
    // without this every `ensureCamera`/`ensureMicrophone` call would throw.
    PermissionsModule(),
    // Camera / gallery / file acquisition. The AI chat composer is the only
    // client consumer today; the scanner source is left unregistered because
    // the client has no document-scanning flow.
    AssetPickerModule(
      config: const AssetPickerConfig(registerScanner: false),
    ),
    AuthModule(
      // Session-boundary hook: every module's dispose() runs whenever a
      // session begins or ends, so per-session in-memory state cannot
      // survive a logout→login transition. Safe to reference
      // `moduleRegistry` here — this closure only runs long after the
      // assignment below completes.
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
    // Map + places. No client screen resolves a location today — the request
    // composer that did has been removed, because a request is created by
    // asking the agent rather than by filling in a form. Kept registered
    // because a chat-driven request still needs `lat`/`lng`, and because
    // tearing the wiring out only to restore it would be churn. The API key
    // is supplied at build time, the same way the provider app does it.
    MapsModule(
      config: MapsConfig(
        placesApiKey: const String.fromEnvironment('MAPS_API_KEY'),
      ),
    ),
    // The request lifecycle. Registered unconditionally — unlike the AI-chat
    // prototype below, these routes must exist in a release build so a push
    // notification can open a request.
    ClientRequestsModule(),
    // The single owner of push registration and notification routing for this
    // app. Registered after AuthModule so the session exists by the time its
    // initialize() runs.
    NotificationsModule(
      resolveNavigator: () => sl<ClientNotificationNavigator>(),
    ),
    // Prototype only: contributes dev-gated routes and registers only
    // per-visit capability factories, so it cannot affect production flows.
    AiChatModule(),
  ]);
  await moduleRegistry.initAll();
}
