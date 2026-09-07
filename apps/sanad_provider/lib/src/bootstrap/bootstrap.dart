import 'package:app_logger/app_logger.dart';
import 'package:core/core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce/hive.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:localization/localization.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanad_provider/firebase_options.dart';
import 'package:sanad_provider/src/app.dart';
import 'package:sanad_provider/src/di/app_di.dart';

/// Initialises the Flutter engine, storage, DI, and runs the app.
///
/// Runs inside a guarded zone so uncaught async, framework, and platform
/// errors are captured by [ErrorReporter]. See `docs/ARCHITECTURE_BLUEPRINT.md`
/// §12.
Future<void> bootstrap() => runGuarded(_bootstrap);

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  installGlobalErrorHandlers();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // MUST run before EasyLocalization.ensureInitialized(): that call latches
  // EasyLocalization's own saved locale into a static, and with
  // `saveLocale: false` a leftover value makes its controller fall through to
  // the DEVICE locale instead of our `startLocale`. Removing the key
  // afterwards is too late (SAN-774).
  final legacyLanguage = await LegacyLocalePreference.takeIfAny();

  await EasyLocalization.ensureInitialized();

  await Future.wait([
    // Load intl locale symbols so DateFormat('h:mm a', 'ar') renders
    // Arabic AM/PM markers (ص/م) rather than falling back to the default
    // en_US 'AM/PM' symbols on the working-hours list (SAN-573).
    initializeDateFormatting('ar'),
    initializeDateFormatting('en'),
    () async {
      final appDir = await getApplicationDocumentsDirectory();
      HydratedBloc.storage = await HydratedStorage.build(
        storageDirectory: HydratedStorageDirectory(appDir.path),
      );
      Hive.init(appDir.path);
    }(),
    // Pre-warm translation assets into Flutter's bundle cache so that
    // EasyLocalization reads from memory instead of disk during widget init.
    rootBundle.loadString(
      'packages/localization/assets/translations/ar-AR.json',
    ),
    rootBundle.loadString(
      'packages/localization/assets/translations/en-US.json',
    ),
  ]);

  await configureDependencies(
    initialLanguage: legacyLanguage ?? AppLanguage.defaultLanguage,
  );

  // Reconcile a hydrated language that disagrees with the legacy one.
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
      // TranslateBloc is the single source of truth for the app language; this
      // only seeds the first frame so there is no flash of the wrong language.
      startLocale: startLanguage.locale,
      fallbackLocale: AppLanguage.fallbackLocale,
      // Never let EasyLocalization keep its own copy of the language — a
      // second persisted store is exactly what allowed the UI locale and the
      // API language to disagree (SAN-774). AppLocaleSync drives it instead.
      saveLocale: false,
      child: const SanadProviderApp(),
    ),
  );
}
