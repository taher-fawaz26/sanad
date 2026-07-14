import 'package:core/core.dart';
import 'package:go_router/go_router.dart';
import 'package:workers/src/di/workers_di.dart';

class WorkersModule extends FeatureModule {
  @override
  String get name => 'workers';

  @override
  String get version => '0.1.0';

  @override
  List<String> get dependencies => const ['auth'];

  @override
  void registerDependencies() => WorkersDI.init();

  @override
  List<RouteBase> routes(FeatureRouteContext ctx) => const [];
}
