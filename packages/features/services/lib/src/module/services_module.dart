import 'package:core/core.dart';
import 'package:go_router/go_router.dart';
import 'package:services/src/di/services_di.dart';

class ServicesModule extends FeatureModule {
  @override
  String get name => 'services';

  @override
  String get version => '0.1.0';

  @override
  List<String> get dependencies => const ['auth'];

  @override
  void registerDependencies() => ServicesDI.init();

  @override
  List<RouteBase> routes(FeatureRouteContext ctx) => const [];
}
