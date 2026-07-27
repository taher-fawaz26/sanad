import 'package:core/core.dart';
import 'package:device/src/config/device_config.dart';
import 'package:device/src/domain/services/app_info_service.dart';
import 'package:device/src/domain/services/biometric_service.dart';
import 'package:device/src/domain/services/clipboard_service.dart';
import 'package:device/src/domain/services/connectivity_service.dart';
import 'package:device/src/domain/services/device_info_service.dart';
import 'package:device/src/domain/services/share_service.dart';
import 'package:device/src/domain/services/url_launcher_service.dart';
import 'package:device/src/infrastructure/implementations/app_info_service_impl.dart';
import 'package:device/src/infrastructure/implementations/biometric_service_impl.dart';
import 'package:device/src/infrastructure/implementations/clipboard_service_impl.dart';
import 'package:device/src/infrastructure/implementations/connectivity_service_impl.dart';
import 'package:device/src/infrastructure/implementations/device_info_service_impl.dart';
import 'package:device/src/infrastructure/implementations/share_service_impl.dart';
import 'package:device/src/infrastructure/implementations/url_launcher_service_impl.dart';
import 'package:device/src/infrastructure/providers/app_info_provider.dart';
import 'package:device/src/infrastructure/providers/biometric_provider.dart';
import 'package:device/src/infrastructure/providers/clipboard_provider.dart';
import 'package:device/src/infrastructure/providers/connectivity_provider.dart';
import 'package:device/src/infrastructure/providers/device_info_provider.dart';
import 'package:device/src/infrastructure/providers/share_provider.dart';
import 'package:device/src/infrastructure/providers/url_launcher_provider.dart';

/// Registers all device-package bindings into the global [GetIt] locator.
///
/// Called by [DeviceModule.registerDependencies]; never called directly by
/// app code.
abstract final class DeviceDI {
  DeviceDI._();

  static void init({DeviceConfig config = const DeviceConfig()}) {
    sl
      ..registerLazySingleton<DeviceConfig>(() => config)
      // --- Providers (plugin wrappers) ---
      ..registerLazySingleton<DeviceInfoProvider>(DeviceInfoProvider.new)
      ..registerLazySingleton<AppInfoProvider>(AppInfoProvider.new)
      ..registerLazySingleton<ConnectivityProvider>(ConnectivityProvider.new)
      ..registerLazySingleton<BiometricProvider>(BiometricProvider.new)
      ..registerLazySingleton<ClipboardProvider>(ClipboardProvider.new)
      ..registerLazySingleton<ShareProvider>(ShareProvider.new)
      ..registerLazySingleton<UrlLauncherProvider>(UrlLauncherProvider.new)
      // --- Services (public contracts) ---
      ..registerLazySingleton<DeviceInfoService>(
        () => DeviceInfoServiceImpl(sl<DeviceInfoProvider>()),
      )
      ..registerLazySingleton<AppInfoService>(
        () => AppInfoServiceImpl(sl<AppInfoProvider>()),
      )
      ..registerLazySingleton<ConnectivityService>(
        () => ConnectivityServiceImpl(sl<ConnectivityProvider>()),
      )
      ..registerLazySingleton<BiometricService>(
        () => BiometricServiceImpl(sl<BiometricProvider>()),
      )
      ..registerLazySingleton<ClipboardService>(
        () => ClipboardServiceImpl(sl<ClipboardProvider>()),
      )
      ..registerLazySingleton<ShareService>(
        () => ShareServiceImpl(sl<ShareProvider>()),
      )
      ..registerLazySingleton<UrlLauncherService>(
        () => UrlLauncherServiceImpl(sl<UrlLauncherProvider>()),
      );
  }
}
