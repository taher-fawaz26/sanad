import 'package:app_logger/app_logger.dart';
import 'package:core/core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:localization/localization.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanad_client/firebase_options.dart';
import 'package:sanad_client/src/app.dart';
import 'package:sanad_client/src/di/app_di.dart';

/// Initialises the Flutter engine, storage, DI, and runs the app.
///
/// Extracted from main.dart to keep the entry-point minimal and to allow
/// flavor-specific entry-points to share this bootstrap sequence.
Future<void> bootstrap() => runGuarded(_bootstrap);

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  installGlobalErrorHandlers();

  // Exactly one initializeApp per app, before anything that touches a Firebase
  // service. `packages/notifications` owns the only FirebaseMessaging usage.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // MUST run before EasyLocalization.ensureInitialized() — see the provider
  // bootstrap for why the ordering matters (SAN-774).
  final legacyLanguage = await LegacyLocalePreference.takeIfAny();

  await EasyLocalization.ensureInitialized();
  // Load intl locale symbols so DateFormat('h:mm a', 'ar') renders Arabic
  // AM/PM markers rather than falling back to en_US (SAN-573).
  await Future.wait([
    initializeDateFormatting('ar'),
    initializeDateFormatting('en'),
  ]);

  final appDir = await getApplicationDocumentsDirectory();
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: HydratedStorageDirectory(appDir.path),
  );
  Hive.init(appDir.path);

  await configureDependencies(
    initialLanguage: legacyLanguage ?? AppLanguage.defaultLanguage,
  );

  if (legacyLanguage != null) {
    LegacyLocalePreference.adopt(sl<TranslateBloc>(), legacyLanguage);
  }

  // The migrated value, when there was one, is the language the user was
  // actually looking at — and `adopt` dispatches an event, which the bloc has
  // not processed yet, so its `state` is still the pre-migration one on this
  // line. Reading it here would flash the wrong language for a frame.
  final startLanguage = legacyLanguage ?? sl<TranslateBloc>().state.language;

  Bloc.observer = AppBlocObserver();

  runApp(
    EasyLocalization(
      supportedLocales: AppLanguage.supportedLocales,
      path: 'packages/localization/assets/translations',
      startLocale: startLanguage.locale,
      fallbackLocale: AppLanguage.fallbackLocale,
      // See the provider bootstrap: TranslateBloc is the only locale store.
      saveLocale: false,
      child: const SanadClientApp(),
    ),
  );
}
