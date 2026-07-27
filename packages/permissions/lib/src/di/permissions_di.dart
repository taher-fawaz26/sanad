import 'package:core/core.dart';
import 'package:permissions/src/config/permission_config.dart';
import 'package:permissions/src/domain/services/permission_service.dart';
import 'package:permissions/src/infrastructure/implementations/permission_service_impl.dart';
import 'package:permissions/src/infrastructure/providers/permission_handler_provider.dart';
import 'package:permissions/src/theme/permission_theme.dart';

/// Registers all permissions-package bindings into the global [GetIt] service
/// locator.
///
/// Called by [PermissionsModule.registerDependencies]; never called directly
/// by app code.
abstract final class PermissionsDI {
  PermissionsDI._();

  static void init({
    PermissionConfig config = const PermissionConfig(),
    PermissionTheme theme = const PermissionTheme(),
  }) {
    sl
      ..registerLazySingleton<PermissionConfig>(() => config)
      ..registerLazySingleton<PermissionTheme>(() => theme)
      ..registerLazySingleton<PermissionHandlerProvider>(
        () => const PermissionHandlerProvider(),
      )
      ..registerLazySingleton<PermissionService>(
        () => PermissionServiceImpl(sl<PermissionHandlerProvider>()),
      );
  }
}
