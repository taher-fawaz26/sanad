import 'package:core/src/module/feature_module.dart';
import 'package:go_router/go_router.dart';

/// Registers and initialises [FeatureModule] instances in dependency order.
class ModuleRegistry {
  ModuleRegistry(this.modules);

  final List<FeatureModule> modules;

  /// All routes from registered modules using [context].
  List<RouteBase> allRoutes(FeatureRouteContext context) => [
        for (final module in modules) ...module.routes(context),
      ];

  /// Registers dependencies and runs `initialize()` in load order.
  Future<void> initAll() async {
    final ordered = _resolveLoadOrder();
    for (final module in ordered) {
      module.registerDependencies();
    }
    for (final module in ordered) {
      await module.initialize();
    }
  }

  List<FeatureModule> _resolveLoadOrder() {
    final byName = {for (final m in modules) m.name: m};
    final visited = <String>{};
    final result = <FeatureModule>[];

    void visit(FeatureModule module) {
      if (visited.contains(module.name)) return;
      for (final dep in module.dependencies) {
        final depModule = byName[dep];
        if (depModule != null) visit(depModule);
      }
      visited.add(module.name);
      result.add(module);
    }

    for (final module in modules) {
      visit(module);
    }
    return result;
  }
}
