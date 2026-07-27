import 'package:core/core.dart';
import 'package:go_router/go_router.dart';
import 'package:maps/src/config/maps_config.dart';
import 'package:maps/src/di/maps_di.dart';

/// Feature module wrapper for [MapsDI].
///
/// Wrap Maps in the same `ModuleRegistry([...])` load-order system every
/// other feature uses, instead of a separate imperative `MapsDI.init(...)`
/// call in the app's DI. Keeps the bootstrap surface uniform and lets
/// `melos doctor` enumerate maps alongside the rest.
class MapsModule extends FeatureModule {
  MapsModule({this.config = const MapsConfig()});

  final MapsConfig config;

  @override
  String get name => 'maps';

  @override
  String get version => '0.1.0';

  @override
  List<String> get dependencies => const [];

  @override
  void registerDependencies() => MapsDI.init(config: config);

  @override
  List<RouteBase> routes(FeatureRouteContext context) => const [];
}
