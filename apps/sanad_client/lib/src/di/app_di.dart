import 'package:account_settings/account_settings.dart';
import 'package:app_logger/app_logger.dart';
import 'package:auth/auth.dart';
import 'package:config/config.dart';
import 'package:contact_verification/contact_verification.dart';
import 'package:core/core.dart';
import 'package:deep_linking/deep_linking.dart';
import 'package:design_system/design_system.dart';
import 'package:device/device.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:localization/localization.dart';
import 'package:network/network.dart';
import 'package:sanad_client/src/config/app_config.dart';
import 'package:sanad_client/src/features/ai_chat/src/module/ai_chat_module.dart';
import 'package:storage/storage.dart';

late final ModuleRegistry moduleRegistry;

/// Registers all application-level dependencies with the service locator.
Future<void> configureDependencies() async {
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

  // ── Deep linking (OS-level incoming URI → GoRouter location) ─────────────
  DeepLinkingDI.init(config: AppConfig.deepLinkConfig);

  // ── Feature modules ────────────────────────────────────────────────────────
  moduleRegistry = ModuleRegistry([
    // Device capability gateway (biometrics, connectivity, clipboard, share,
    // device/app info). Registered first: it declares no dependencies and
    // other modules resolve its services lazily.
    DeviceModule(),
    AuthModule(
      // Session-boundary hook: every module's dispose() runs whenever a
      // session begins or ends, so per-session in-memory state cannot
      // survive a logout→login transition. Safe to reference
      // `moduleRegistry` here — this closure only runs long after the
      // assignment below completes.
      onSessionBoundary: () => moduleRegistry.disposeAll(),
    ),
    ContactVerificationModule(),
    AccountSettingsModule(),
    // Prototype only: contributes a dev-gated route and registers nothing
    // globally, so it cannot affect production flows.
    AiChatModule(),
  ]);
  await moduleRegistry.initAll();
}
