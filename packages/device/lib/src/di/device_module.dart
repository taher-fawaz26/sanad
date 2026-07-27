import 'package:core/core.dart';
import 'package:device/src/config/device_config.dart';
import 'package:device/src/di/device_di.dart';
import 'package:go_router/go_router.dart';

/// [FeatureModule] registration for the device package.
///
/// Add to the app's [ModuleRegistry] at bootstrap:
///
/// ```dart
/// moduleRegistry = ModuleRegistry([
///   DeviceModule(),
///   PermissionsModule(),
///   // ...
/// ]);
/// ```
class DeviceModule extends FeatureModule {
  DeviceModule({DeviceConfig config = const DeviceConfig()}) : _config = config;

  final DeviceConfig _config;

  @override
  String get name => 'device';

  @override
  String get version => '0.1.0';

  @override
  List<String> get dependencies => const [];

  @override
  void registerDependencies() => DeviceDI.init(config: _config);

  @override
  List<RouteBase> routes(FeatureRouteContext context) => const [];
}
