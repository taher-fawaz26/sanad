import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeModule extends FeatureModule {
  _FakeModule(this.name, {this.dependencies = const []});

  @override
  final String name;

  @override
  final List<String> dependencies;

  @override
  String get version => '0.0.0';

  final registeredCalls = <String>[];
  final initializedCalls = <String>[];
  final disposedCalls = <String>[];

  /// Shared across every fake module in a test so call order is observable.
  static final log = <String>[];

  @override
  void registerDependencies() {
    registeredCalls.add(name);
    log.add('register:$name');
  }

  @override
  Future<void> initialize() async {
    initializedCalls.add(name);
    log.add('init:$name');
  }

  @override
  void dispose() {
    disposedCalls.add(name);
    log.add('dispose:$name');
  }

  @override
  List<RouteBase> routes(FeatureRouteContext context) => const [];
}

void main() {
  setUp(_FakeModule.log.clear);

  test(
    'initAll registers dependencies for every module in load order',
    () async {
      final auth = _FakeModule('auth');
      final feature = _FakeModule('feature', dependencies: ['auth']);
      final registry = ModuleRegistry([feature, auth]);

      await registry.initAll();

      expect(_FakeModule.log, [
        'register:auth',
        'register:feature',
        'init:auth',
        'init:feature',
      ]);
    },
  );

  test(
    'disposeAll runs dispose() for every module in the REVERSE of load order',
    () {
      final auth = _FakeModule('auth');
      final feature = _FakeModule('feature', dependencies: ['auth']);

      ModuleRegistry([auth, feature]).disposeAll();

      expect(_FakeModule.log, ['dispose:feature', 'dispose:auth']);
    },
  );

  test(
    'disposeAll can be called without a prior initAll (idempotent hook)',
    () {
      final module = _FakeModule('solo');
      final registry = ModuleRegistry([module]);

      expect(registry.disposeAll, returnsNormally);
      expect(module.disposedCalls, ['solo']);
    },
  );

  test(
    'disposeAll can be called multiple times (fired on every session boundary)',
    () {
      final module = _FakeModule('solo');

      ModuleRegistry([module])
        ..disposeAll()
        ..disposeAll();

      expect(module.disposedCalls, ['solo', 'solo']);
    },
  );
}
