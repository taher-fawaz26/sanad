import 'package:app_logger/app_logger.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce/hive.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
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

  await Future.wait([
    EasyLocalization.ensureInitialized(),
    // Load intl locale symbols so DateFormat('h:mm a', 'ar') renders
    // Arabic AM/PM markers (ص/م) rather than falling back to the default
    // en_US 'AM/PM' symbols on the working-hours list (SAN-573).
    initializeDateFormatting('ar', null),
    initializeDateFormatting('en', null),
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

  await configureDependencies();

  Bloc.observer = AppBlocObserver();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('ar', 'AR'), Locale('en', 'US')],
      path: 'packages/localization/assets/translations',
      startLocale: const Locale('ar', 'AR'),
      fallbackLocale: const Locale('en', 'US'),
      child: const SanadProviderApp(),
    ),
  );
}
