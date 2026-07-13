import 'package:app_logger/app_logger.dart';
import 'package:auth/auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce/hive.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanad_provider/src/app.dart';
import 'package:sanad_provider/src/di/app_di.dart';

/// Initialises the Flutter engine, storage, DI, and runs the app.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Future.wait([
    EasyLocalization.ensureInitialized(),
    () async {
      final appDir = await getApplicationDocumentsDirectory();
      HydratedBloc.storage = await HydratedStorage.build(
        storageDirectory: HydratedStorageDirectory(appDir.path),
      );
      Hive.init(appDir.path);
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(UserAdapter());
      }
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
