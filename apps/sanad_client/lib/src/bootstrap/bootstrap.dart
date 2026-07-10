import 'package:app_logger/app_logger.dart';
import 'package:auth/auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanad_client/src/app.dart';
import 'package:sanad_client/src/di/app_di.dart';

/// Initialises the Flutter engine, storage, DI, and runs the app.
///
/// Extracted from main.dart to keep the entry-point minimal and to allow
/// flavor-specific entry-points to share this bootstrap sequence.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  final appDir = await getApplicationDocumentsDirectory();
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: HydratedStorageDirectory(appDir.path),
  );
  Hive.init(appDir.path);

  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(UserAdapter());
  }

  await configureDependencies();

  Bloc.observer = AppBlocObserver();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('ar', 'AR'), Locale('en', 'US')],
      path: 'packages/localization/assets/translations',
      startLocale: const Locale('ar', 'AR'),
      fallbackLocale: const Locale('en', 'US'),
      child: const SandClientApp(),
    ),
  );
}
