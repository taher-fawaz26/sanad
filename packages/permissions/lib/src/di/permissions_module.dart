import 'package:core/core.dart';
import 'package:go_router/go_router.dart';
import 'package:permissions/src/config/permission_config.dart';
import 'package:permissions/src/di/permissions_di.dart';
import 'package:permissions/src/theme/permission_theme.dart';

/// [FeatureModule] registration for the permissions package.
///
/// Add this to the app's [ModuleRegistry] at bootstrap:
///
/// ```dart
/// moduleRegistry = ModuleRegistry([
///   PermissionsModule(),
///   AuthModule(),
///   // ...
/// ]);
/// ```
///
/// Supply [config] and [theme] to override defaults:
///
/// ```dart
/// PermissionsModule(
///   config: PermissionConfig(
///     defaultPolicy: PermissionPolicy(
///       showRationale: true,
///       showSettingsDialog: true,
///     ),
///   ),
///   theme: PermissionTheme(
///     texts: PermissionTexts(
///       allowButtonLabel: 'Grant Access',
///     ),
///   ),
/// )
/// ```
class PermissionsModule extends FeatureModule {
  PermissionsModule({
    PermissionConfig config = const PermissionConfig(),
    PermissionTheme theme = const PermissionTheme(),
  }) : _config = config,
       _theme = theme;

  final PermissionConfig _config;
  final PermissionTheme _theme;

  @override
  String get name => 'permissions';

  @override
  String get version => '0.1.0';

  @override
  List<String> get dependencies => const [];

  @override
  void registerDependencies() => PermissionsDI.init(
    config: _config,
    theme: _theme,
  );

  @override
  List<RouteBase> routes(FeatureRouteContext context) => const [];
}
