// ignore_for_file: avoid_print

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sanad_tools/workspace.dart';

/// Scaffolds feature packages or app features.
///
/// Positional form (use with `melos run feature:create -- ...`):
///   dart run bin/feature_generator.dart <name> shared
///   dart run bin/feature_generator.dart <name> provider
///   dart run bin/feature_generator.dart <name> client
///   dart run bin/feature_generator.dart <name> provider with-backend
///
/// Flag form (direct dart run):
///   dart run bin/feature_generator.dart <name> --shared
///   dart run bin/feature_generator.dart <name> --app provider
///   dart run bin/feature_generator.dart <name> --app client
void main(List<String> args) {
  if (args.isEmpty || args.contains('--help') || args.contains('help')) {
    _printUsage();
    exit(args.isEmpty ? 1 : 0);
  }

  final ws = Workspace.find();
  // Name is always the first argument that is not a --flag.
  final name = args.firstWhere((a) => !a.startsWith('-'), orElse: () => '');
  if (name.isEmpty) {
    print('Error: feature name is required.');
    _printUsage();
    exit(1);
  }
  final flags = _parseFlags(args, name);
  final names = FeatureNames(name);

  if (flags.shared) {
    _createSharedPackage(ws, names, flags);
  } else if (flags.app != null) {
    _createAppFeature(ws, names, flags);
    if (flags.withBackend) {
      _createSharedPackage(ws, names, _FeatureFlags(shared: true, withBackend: true));
    }
  } else {
    print('Error: specify a mode. Examples:');
    print('  melos run feature:create -- orders shared');
    print('  melos run feature:create -- branches provider');
    print('  melos run feature:create -- profile client');
    exit(1);
  }
}

void _printUsage() {
  print('''
Sanad Feature Generator

Via Melos (recommended):
  melos run feature:create -- <name> shared
  melos run feature:create -- <name> provider
  melos run feature:create -- <name> client
  melos run feature:create -- <name> provider with-backend

Direct dart run:
  dart run bin/feature_generator.dart <name> --shared
  dart run bin/feature_generator.dart <name> --app provider
  dart run bin/feature_generator.dart <name> --app client

Modes:
  shared           Full clean-arch package under packages/
  provider         UI-only scaffold under apps/sanad_provider/
  client           UI-only scaffold under apps/sanad_client/

Options (append after mode):
  with-backend     Also create packages/<name>/ when using provider|client
  assets           Add assets/ folder and pubspec declaration
  no-tests         Skip test stub generation
''');
}

class _FeatureFlags {
  _FeatureFlags({
    this.shared = false,
    this.app,
    this.withBackend = false,
    this.assets = false,
    this.noTests = false,
  });

  final bool shared;
  final String? app;
  final bool withBackend;
  final bool assets;
  final bool noTests;
}

/// Parses flags from both positional and --flag style args.
///
/// Positional style (Melos-friendly): `orders shared`, `branches provider`
/// Flag style (dart run): `orders --shared`, `branches --app provider`
/// Mixed style: `orders shared --no-tests` (positional mode + flag options)
_FeatureFlags _parseFlags(List<String> args, String name) {
  // Strip the feature name from consideration.
  final rest = args.where((a) => a != name).toList();

  // Check for an explicit positional mode word first.
  const modeWords = {'shared', 'provider', 'client'};
  final positionalMode =
      rest.where((a) => !a.startsWith('-')).where(modeWords.contains).firstOrNull;

  // Boolean options — accept both positional and --flag forms.
  bool hasOpt(String positional, String flag) =>
      rest.contains(positional) || rest.contains(flag);

  if (positionalMode != null) {
    switch (positionalMode) {
      case 'shared':
        return _FeatureFlags(
          shared: true,
          assets: hasOpt('assets', '--assets'),
          noTests: hasOpt('no-tests', '--no-tests'),
        );
      case 'provider':
        return _FeatureFlags(
          app: 'provider',
          withBackend: hasOpt('with-backend', '--with-backend'),
          assets: hasOpt('assets', '--assets'),
          noTests: hasOpt('no-tests', '--no-tests'),
        );
      case 'client':
        return _FeatureFlags(
          app: 'client',
          withBackend: hasOpt('with-backend', '--with-backend'),
          assets: hasOpt('assets', '--assets'),
          noTests: hasOpt('no-tests', '--no-tests'),
        );
    }
  }

  // Fall back to --flag style (direct dart run without positional mode).
  if (rest.any((a) => a.startsWith('--'))) {
    String? app;
    if (rest.contains('--app')) {
      final idx = rest.indexOf('--app');
      if (idx + 1 < rest.length) app = rest[idx + 1];
    }
    return _FeatureFlags(
      shared: rest.contains('--shared'),
      app: app,
      withBackend: rest.contains('--with-backend'),
      assets: rest.contains('--assets'),
      noTests: rest.contains('--no-tests'),
    );
  }

  return _FeatureFlags();
}

class FeatureNames {
  FeatureNames(String raw)
      : snake = raw.replaceAll('-', '_').toLowerCase(),
        pascal = _toPascal(raw);

  final String snake;
  final String pascal;

  String get upperSnake => snake.toUpperCase();

  static String _toPascal(String raw) {
    return raw
        .replaceAll('-', '_')
        .split('_')
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase())
        .join();
  }
}

void _createSharedPackage(Workspace ws, FeatureNames n, _FeatureFlags flags) {
  final pkgDir = p.join(ws.root, 'packages', n.snake);
  if (Directory(pkgDir).existsSync()) {
    print('Error: packages/${n.snake} already exists');
    exit(1);
  }

  _writeFiles(pkgDir, n, flags);
  _registerPackage(ws, n.snake);
  _appendL10nKeys(ws, n.snake);

  print('✅ Created packages/${n.snake}/');
  print('   Run: melos bootstrap');
  print('   Add: ${n.pascal}Module() to app module list');
}

void _createAppFeature(Workspace ws, FeatureNames n, _FeatureFlags flags) {
  final appName = flags.app == 'client' ? 'sanad_client' : 'sanad_provider';
  final featureDir = p.join(ws.root, 'apps', appName, 'lib', 'src', 'features', n.snake);

  if (Directory(featureDir).existsSync()) {
    print('Error: apps/$appName/.../features/${n.snake} already exists');
    exit(1);
  }

  Directory(p.join(featureDir, 'routes')).createSync(recursive: true);
  Directory(p.join(featureDir, 'widgets')).createSync(recursive: true);

  final pageClass = '${n.pascal}Page';
  File(p.join(featureDir, '${n.snake}_page.dart')).writeAsStringSync('''
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// ${n.pascal} screen — app-specific UI shell.
class $pageClass extends StatelessWidget {
  const $pageClass({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppNavBar(title: '${n.snake}.title'.tr()),
      body: Center(child: Text('${n.snake}.title'.tr())),
    );
  }
}
''');

  File(p.join(featureDir, 'routes', '${n.snake}_routes.dart')).writeAsStringSync('''
/// Local route constants for the ${n.snake} app feature.
abstract final class ${n.pascal}Routes {
  static const list = '/${n.snake}';
}
''');

  if (!flags.noTests) {
    final testDir = p.join(ws.root, 'apps', appName, 'test', 'features', n.snake);
    Directory(testDir).createSync(recursive: true);
    File(p.join(testDir, '${n.snake}_page_test.dart')).writeAsStringSync('''
import 'package:flutter_test/flutter_test.dart';
import 'package:$appName/src/features/${n.snake}/${n.snake}_page.dart';

void main() {
  testWidgets('renders ${n.pascal}Page', (tester) async {
    // TODO: pump with pumpDsWidget when app test harness is configured
    expect(const $pageClass(), isNotNull);
  });
}
''');
  }

  _appendL10nKeys(ws, n.snake);
  print('✅ Created apps/$appName/.../features/${n.snake}/');
  print('   Register ${n.pascal}Routes.list in the app router');
}

void _writeFiles(String pkgDir, FeatureNames n, _FeatureFlags flags) {
  final dirs = [
    'lib/src/data/datasources',
    'lib/src/data/models/requests',
    'lib/src/data/repositories',
    'lib/src/data/endpoints',
    'lib/src/domain/entities',
    'lib/src/domain/repositories',
    'lib/src/domain/usecases',
    'lib/src/presentation/bloc',
    'lib/src/presentation/pages',
    'lib/src/presentation/widgets',
    'lib/src/di',
    'lib/src/routes',
    'lib/src/module',
  ];
  for (final dir in dirs) {
    Directory(p.join(pkgDir, dir)).createSync(recursive: true);
  }
  if (flags.assets) {
    Directory(p.join(pkgDir, 'assets')).createSync(recursive: true);
  }
  if (!flags.noTests) {
    for (final dir in [
      'test/src/data/datasources',
      'test/src/data/repositories',
      'test/src/domain/usecases',
      'test/src/presentation/bloc',
    ]) {
      Directory(p.join(pkgDir, dir)).createSync(recursive: true);
    }
  }

  File(p.join(pkgDir, 'analysis_options.yaml')).writeAsStringSync('''
include: package:very_good_analysis/analysis_options.yaml

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"

linter:
  rules:
    public_member_api_docs: false
    prefer_single_quotes: true
    always_use_package_imports: true
''');

  final assetsBlock = flags.assets
      ? '''

flutter:
  assets:
    - assets/
'''
      : '';

  File(p.join(pkgDir, 'pubspec.yaml')).writeAsStringSync('''
name: ${n.snake}
description: ${n.pascal} feature — domain, data, presentation, DI, and routes.
version: 0.1.0
publish_to: none
resolution: workspace

environment:
  sdk: ">=3.11.0 <4.0.0"
  flutter: ">=3.19.0"

dependencies:
  core:
    path: ../../core
  design_system:
    path: ../../design_system
  easy_localization: ^3.0.8
  equatable: ^2.1.0
  flutter:
    sdk: flutter
  flutter_bloc: ^9.1.1
  flutter_hooks: ^0.21.3+1
  fpdart: ^1.2.0
  go_router: ^17.3.0
  localization:
    path: ../../localization
  network:
    path: ../../network

dev_dependencies:
  bloc_test: ^10.0.0
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.4
  testing:
    path: ../../testing
  very_good_analysis: ^9.0.0
$assetsBlock''');

  File(p.join(pkgDir, 'README.md')).writeAsStringSync('''
# ${n.pascal}

${n.pascal} feature package.

## Usage

```dart
import 'package:${n.snake}/${n.snake}.dart';
```

## DI

Call `${n.pascal}DI.init()` during app bootstrap, or register `${n.pascal}Module()`.
''');

  // Core source files — abbreviated scaffold matching packages/auth patterns
  _writeSharedSources(pkgDir, n, flags);
}

void _writeSharedSources(String pkgDir, FeatureNames n, _FeatureFlags flags) {
  final s = n.snake;
  final p = n.pascal;

  File('$pkgDir/lib/$s.dart').writeAsStringSync('''
/// ${p} feature package.
library;

export 'src/di/${s}_di.dart';
export 'src/domain/entities/${s}_entity.dart';
export 'src/domain/repositories/${s}_repository.dart';
export 'src/domain/usecases/fetch_${s}_usecase.dart';
export 'src/domain/usecases/${s}_params.dart';
export 'src/module/${s}_module.dart';
export 'src/presentation/bloc/${s}_bloc.dart';
export 'src/presentation/pages/${s}_page.dart';
export 'src/routes/${s}_routes.dart';
''');

  File('$pkgDir/lib/src/data/endpoints/${s}_api_paths.dart').writeAsStringSync('''
abstract final class ${p}ApiPaths {
  static const list = '$s';
}
''');

  File('$pkgDir/lib/src/domain/entities/${s}_entity.dart').writeAsStringSync('''
import 'package:equatable/equatable.dart';

class ${p}Entity extends Equatable {
  const ${p}Entity({required this.id});

  final String id;

  @override
  List<Object?> get props => [id];
}
''');

  File('$pkgDir/lib/src/domain/repositories/${s}_repository.dart').writeAsStringSync('''
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:$s/src/domain/entities/${s}_entity.dart';

abstract class ${p}Repository {
  TaskEither<Failure, List<${p}Entity>> fetch${p}s();
}
''');

  File('$pkgDir/lib/src/data/models/${s}_response_model.dart').writeAsStringSync('''
import 'package:$s/src/domain/entities/${s}_entity.dart';

class ${p}ResponseModel {
  const ${p}ResponseModel({required this.id});

  factory ${p}ResponseModel.fromJson(Map<String, dynamic> json) =>
      ${p}ResponseModel(id: json['id'] as String);

  final String id;

  ${p}Entity toEntity() => ${p}Entity(id: id);
}
''');

  File('$pkgDir/lib/src/data/datasources/${s}_remote_datasource.dart').writeAsStringSync('''
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';
import 'package:$s/src/data/endpoints/${s}_api_paths.dart';
import 'package:$s/src/data/models/${s}_response_model.dart';

abstract class ${p}RemoteDataSource {
  TaskEither<Failure, List<${p}ResponseModel>> fetch${p}s();
}

class ${p}RemoteDataSourceImpl implements ${p}RemoteDataSource {
  const ${p}RemoteDataSourceImpl(this._apiClient);

  final BaseApiClient _apiClient;

  @override
  TaskEither<Failure, List<${p}ResponseModel>> fetch${p}s() =>
      _apiClient.request(
        path: ${p}ApiPaths.list,
        method: RequestMethod.get,
        parser: (data) => (data as List<dynamic>)
            .map((e) => ${p}ResponseModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
''');

  File('$pkgDir/lib/src/data/repositories/${s}_repository_impl.dart').writeAsStringSync('''
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:$s/src/data/datasources/${s}_remote_datasource.dart';
import 'package:$s/src/domain/entities/${s}_entity.dart';
import 'package:$s/src/domain/repositories/${s}_repository.dart';

class ${p}RepositoryImpl implements ${p}Repository {
  const ${p}RepositoryImpl(this._remote);

  final ${p}RemoteDataSource _remote;

  @override
  TaskEither<Failure, List<${p}Entity>> fetch${p}s() =>
      _remote.fetch${p}s().map((list) => list.map((m) => m.toEntity()).toList());
}
''');

  File('$pkgDir/lib/src/domain/usecases/${s}_params.dart').writeAsStringSync('''
import 'package:equatable/equatable.dart';

class Fetch${p}Params extends Equatable {
  const Fetch${p}Params();

  @override
  List<Object?> get props => [];
}
''');

  File('$pkgDir/lib/src/domain/usecases/fetch_${s}_usecase.dart').writeAsStringSync('''
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:$s/src/domain/entities/${s}_entity.dart';
import 'package:$s/src/domain/repositories/${s}_repository.dart';
import 'package:$s/src/domain/usecases/${s}_params.dart';

class Fetch${p}UseCase implements UseCase<List<${p}Entity>, Fetch${p}Params> {
  const Fetch${p}UseCase(this._repository);

  final ${p}Repository _repository;

  @override
  TaskEither<Failure, List<${p}Entity>> call(Fetch${p}Params params) =>
      _repository.fetch${p}s();
}
''');

  File('$pkgDir/lib/src/presentation/bloc/${s}_bloc.dart').writeAsStringSync('''
import 'package:bloc/bloc.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:$s/src/domain/entities/${s}_entity.dart';
import 'package:$s/src/domain/usecases/fetch_${s}_usecase.dart';
import 'package:$s/src/domain/usecases/${s}_params.dart';

part '${s}_event.dart';
part '${s}_state.dart';

class ${p}Bloc extends Bloc<${p}Event, ${p}State> {
  ${p}Bloc({required Fetch${p}UseCase fetch${p}UseCase})
      : _fetch${p}UseCase = fetch${p}UseCase,
        super(const ${p}InitialState()) {
    on<Fetch${p}Event>(_onFetch);
  }

  final Fetch${p}UseCase _fetch${p}UseCase;

  Future<void> _onFetch(Fetch${p}Event event, Emitter<${p}State> emit) async {
    emit(const ${p}LoadingState());
    final result = await _fetch${p}UseCase(const Fetch${p}Params()).run();
    result.fold(
      (failure) => emit(${p}FailureState(failure.message)),
      (items) => emit(${p}SuccessState(items: items)),
    );
  }
}
''');

  File('$pkgDir/lib/src/presentation/bloc/${s}_event.dart').writeAsStringSync('''
part of '${s}_bloc.dart';

sealed class ${p}Event extends Equatable {
  const ${p}Event();

  @override
  List<Object?> get props => [];
}

class Fetch${p}Event extends ${p}Event {
  const Fetch${p}Event();
}
''');

  File('$pkgDir/lib/src/presentation/bloc/${s}_state.dart').writeAsStringSync('''
part of '${s}_bloc.dart';

sealed class ${p}State extends Equatable {
  const ${p}State();

  @override
  List<Object?> get props => [];
}

class ${p}InitialState extends ${p}State {
  const ${p}InitialState();
}

class ${p}LoadingState extends ${p}State {
  const ${p}LoadingState();
}

class ${p}SuccessState extends ${p}State {
  const ${p}SuccessState({required this.items});

  final List<${p}Entity> items;

  @override
  List<Object?> get props => [items];
}

class ${p}FailureState extends ${p}State {
  const ${p}FailureState(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
''');

  File('$pkgDir/lib/src/presentation/pages/${s}_page.dart').writeAsStringSync('''
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:$s/src/presentation/bloc/${s}_bloc.dart';

class ${p}Page extends HookWidget {
  const ${p}Page({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<${p}Bloc, ${p}State>(
      listener: (_, __) {},
      builder: (context, state) {
        return Scaffold(
          appBar: AppNavBar(title: '$s.title'.tr()),
          body: switch (state) {
            ${p}LoadingState() => const Center(child: AppLoadingIndicator()),
            ${p}FailureState(:final message) => Center(child: Text(message)),
            ${p}SuccessState(:final items) => ListView.builder(
                itemCount: items.length,
                itemBuilder: (_, i) => ListTile(title: Text(items[i].id)),
              ),
            _ => const SizedBox.shrink(),
          },
        );
      },
    );
  }
}
''');

  File('$pkgDir/lib/src/routes/${s}_routes.dart').writeAsStringSync('''
abstract final class ${p}Routes {
  static const list = '/$s';
}
''');

  File('$pkgDir/lib/src/di/${s}_di.dart').writeAsStringSync('''
import 'package:core/core.dart';
import 'package:network/network.dart';
import 'package:$s/src/data/datasources/${s}_remote_datasource.dart';
import 'package:$s/src/data/repositories/${s}_repository_impl.dart';
import 'package:$s/src/domain/repositories/${s}_repository.dart';
import 'package:$s/src/domain/usecases/fetch_${s}_usecase.dart';
import 'package:$s/src/presentation/bloc/${s}_bloc.dart';

class ${p}DI {
  ${p}DI._();

  static void init() {
    sl
      ..registerLazySingleton<${p}RemoteDataSource>(
        () => ${p}RemoteDataSourceImpl(sl<BaseApiClient>()),
      )
      ..registerLazySingleton<${p}Repository>(
        () => ${p}RepositoryImpl(sl<${p}RemoteDataSource>()),
      )
      ..registerLazySingleton(() => Fetch${p}UseCase(sl<${p}Repository>()))
      ..registerFactory(() => ${p}Bloc(fetch${p}UseCase: sl<Fetch${p}UseCase>()));
  }
}
''');

  File('$pkgDir/lib/src/module/${s}_module.dart').writeAsStringSync('''
import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:$s/src/di/${s}_di.dart';
import 'package:$s/src/presentation/bloc/${s}_bloc.dart';
import 'package:$s/src/presentation/pages/${s}_page.dart';
import 'package:$s/src/routes/${s}_routes.dart';

class ${p}Module extends FeatureModule {
  @override
  String get name => '$s';

  @override
  String get version => '0.1.0';

  @override
  List<String> get dependencies => const [];

  @override
  void registerDependencies() => ${p}DI.init();

  @override
  List<RouteBase> routes(FeatureRouteContext context) => [
        GoRoute(
          path: ${p}Routes.list,
          builder: (ctx, state) => BlocProvider(
            create: (_) => sl<${p}Bloc>()..add(const Fetch${p}Event()),
            child: const ${p}Page(),
          ),
        ),
      ];
}
''');

  if (!flags.noTests) {
    File('$pkgDir/test/src/domain/usecases/fetch_${s}_usecase_test.dart').writeAsStringSync('''
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:$s/src/domain/entities/${s}_entity.dart';
import 'package:$s/src/domain/repositories/${s}_repository.dart';
import 'package:$s/src/domain/usecases/fetch_${s}_usecase.dart';
import 'package:$s/src/domain/usecases/${s}_params.dart';

class _Mock${p}Repository extends Mock implements ${p}Repository {}

void main() {
  late _Mock${p}Repository mockRepo;
  late Fetch${p}UseCase useCase;

  setUp(() {
    mockRepo = _Mock${p}Repository();
    useCase = Fetch${p}UseCase(mockRepo);
  });

  test('returns items when repository succeeds', () async {
    const entities = [${p}Entity(id: '1')];
    when(() => mockRepo.fetch${p}s()).thenReturn(TaskEither.right(entities));

    final result = await useCase(const Fetch${p}Params()).run();

    expect(result.isRight(), isTrue);
  });
}
''');
  }
}

void _registerPackage(Workspace ws, String name) {
  final rootPubspecPath = p.join(ws.root, 'pubspec.yaml');
  final entry = '  - packages/$name';

  final content = File(rootPubspecPath).readAsStringSync();
  if (content.contains('packages/$name')) return;
  final updated = content.replaceFirst('workspace:', 'workspace:\n$entry');
  File(rootPubspecPath).writeAsStringSync(updated);
}

void _appendL10nKeys(Workspace ws, String feature) {
  for (final locale in ['en-US', 'ar-AR']) {
    final path = p.join(
      ws.root,
      'packages/localization/assets/translations/$locale.json',
    );
    if (!File(path).existsSync()) continue;
    final content = File(path).readAsStringSync().trimRight();
    if (content.contains('"$feature"')) continue;

    // Simple JSON append — add feature block before closing brace
    final insertion = locale == 'en-US'
        ? ''',  "$feature": {
    "title": "${_titleCase(feature)}",
    "empty_title": "No $feature yet",
    "empty_description": "Your $feature will appear here"
  }'''
        : ''',  "$feature": {
    "title": "",
    "empty_title": "",
    "empty_description": ""
  }''';

    final updated = content.replaceAll(RegExp(r'\s*\}\s*$'), '$insertion\n}');
    File(path).writeAsStringSync(updated);
  }
}

String _titleCase(String snake) =>
    snake.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
