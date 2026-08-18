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

  /// Disposes every module's per-session state, in the reverse of load
  /// order (mirroring a stack unwind, so a module's dependencies are still
  /// intact while it tears down).
  ///
  /// This is the session-boundary hook: fired whenever the authenticated
  /// identity changes (login, logout, 401, account replacement), so a
  /// module holding in-memory state scoped to "the current user" — a
  /// cache, a live stream, anything that isn't already a fresh-per-route
  /// BLoC — has a single, guaranteed point to reset it. Most modules have
  /// nothing to do here and rely on [FeatureModule.dispose]'s no-op default.
  void disposeAll() {
    for (final module in _resolveLoadOrder().reversed) {
      module.dispose();
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
