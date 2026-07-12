// ignore_for_file: avoid_print

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sanad_tools/workspace.dart';

/// Scaffolds infrastructure, shared, feature, or utility packages.
///
/// Positional form (use with `melos run package:create -- ...`):
///   dart run bin/package_generator.dart analytics infrastructure
///   dart run bin/package_generator.dart localization shared
///   dart run bin/package_generator.dart payments feature
///   dart run bin/package_generator.dart date_formatter utility
///
/// Flag form (direct dart run):
///   dart run bin/package_generator.dart analytics --type infrastructure
void main(List<String> args) {
  if (args.isEmpty || args.contains('--help') || args.contains('help')) {
    _printUsage();
    exit(args.isEmpty ? 1 : 0);
  }

  final ws = Workspace.find();
  final name = args.firstWhere((a) => !a.startsWith('-'), orElse: () => '');
  if (name.isEmpty) {
    print('Error: package name is required.');
    _printUsage();
    exit(1);
  }
  final type = _parseType(args, name);

  if (type == 'feature') {
    // Delegate to feature generator
    final result = Process.runSync(
      'dart',
      ['run', 'bin/feature_generator.dart', name, '--shared'],
      workingDirectory: p.join(ws.root, 'tools'),
    );
    stdout.write(result.stdout);
    stderr.write(result.stderr);
    exit(result.exitCode);
    return;
  }

  final names = _PackageNames(name);
  final pkgDir = p.join(ws.root, 'packages', names.snake);
  if (Directory(pkgDir).existsSync()) {
    print('Error: packages/${names.snake} already exists');
    exit(1);
  }

  switch (type) {
    case 'infrastructure':
      _createInfrastructure(pkgDir, names);
    case 'shared':
      _createShared(pkgDir, names);
    case 'utility':
      _createUtility(pkgDir, names);
    default:
      print('Unknown type: $type');
      exit(1);
  }

  _registerPackage(ws, names.snake);
  _appendPackageGuide(ws, names);

  print('✅ Created packages/${names.snake}/ ($type)');
  print('   Run: melos bootstrap');
}

void _printUsage() {
  print('''
Sanad Package Generator

Via Melos (recommended):
  melos run package:create -- <name> infrastructure
  melos run package:create -- <name> shared
  melos run package:create -- <name> feature
  melos run package:create -- <name> utility

Direct dart run:
  dart run bin/package_generator.dart <name> --type infrastructure

Types:
  infrastructure  Abstract service + impl (depends on core)
  shared          Minimal Flutter package (assets, constants)
  feature         Delegates to feature_generator (shared mode)
  utility         Pure Dart utility package
''');
}

/// Parses the package type from both positional and --type flag styles.
String _parseType(List<String> args, String name) {
  const validTypes = {'infrastructure', 'shared', 'feature', 'utility'};

  // --flag style
  if (args.contains('--type')) {
    final idx = args.indexOf('--type');
    if (idx + 1 >= args.length) {
      print('Error: --type requires a value');
      exit(1);
    }
    return args[idx + 1];
  }

  // Positional style: first arg that is not the name and is a valid type
  final rest = args.where((a) => a != name && !a.startsWith('-')).toList();
  if (rest.isNotEmpty && validTypes.contains(rest.first)) {
    return rest.first;
  }

  print('Error: type is required. Use one of: ${validTypes.join(', ')}');
  exit(1);
}

class _PackageNames {
  _PackageNames(String raw)
      : snake = raw.replaceAll('-', '_').toLowerCase(),
        pascal = raw
            .replaceAll('-', '_')
            .split('_')
            .map((p) => p[0].toUpperCase() + p.substring(1))
            .join();

  final String snake;
  final String pascal;
}

void _createInfrastructure(String pkgDir, _PackageNames n) {
  _basePackage(pkgDir, n, flutter: true, coreDep: true);
  Directory(p.join(pkgDir, 'lib', 'src')).createSync(recursive: true);

  File(p.join(pkgDir, 'lib', '${n.snake}.dart')).writeAsStringSync('''
/// ${n.pascal} infrastructure package.
library;

export 'src/${n.snake}_service.dart';
export 'src/${n.snake}_service_impl.dart';
''');

  File(p.join(pkgDir, 'lib', 'src', '${n.snake}_service.dart')).writeAsStringSync('''
/// Abstract ${n.pascal} service contract.
abstract interface class ${n.pascal}Service {
  Future<void> initialize();
}
''');

  File(p.join(pkgDir, 'lib', 'src', '${n.snake}_service_impl.dart')).writeAsStringSync('''
import 'package:${n.snake}/${n.snake}.dart';

class ${n.pascal}ServiceImpl implements ${n.pascal}Service {
  @override
  Future<void> initialize() async {}
}
''');
}

void _createShared(String pkgDir, _PackageNames n) {
  _basePackage(pkgDir, n, flutter: true, coreDep: false);
  Directory(p.join(pkgDir, 'lib', 'src')).createSync(recursive: true);

  File(p.join(pkgDir, 'lib', '${n.snake}.dart')).writeAsStringSync('''
/// ${n.pascal} shared package.
library;

// Add shared constants, configs, or helpers here.
''');
}

void _createUtility(String pkgDir, _PackageNames n) {
  _basePackage(pkgDir, n, flutter: false, coreDep: false);
  Directory(p.join(pkgDir, 'lib', 'src')).createSync(recursive: true);

  File(p.join(pkgDir, 'lib', '${n.snake}.dart')).writeAsStringSync('''
/// ${n.pascal} utility package — pure Dart.
library;

// Add pure Dart utilities here.
''');
}

void _basePackage(String pkgDir, _PackageNames n,
    {required bool flutter, required bool coreDep}) {
  Directory(p.join(pkgDir, 'lib')).createSync(recursive: true);
  Directory(p.join(pkgDir, 'test')).createSync(recursive: true);

  File(p.join(pkgDir, 'analysis_options.yaml')).writeAsStringSync('''
include: package:very_good_analysis/analysis_options.yaml
''');

  final flutterBlock = flutter
      ? '''
  flutter:
    sdk: flutter
'''
      : '';

  final coreBlock = coreDep
      ? '''
  core:
    path: ../core
'''
      : '';

  final devTest = flutter
      ? '''
  flutter_test:
    sdk: flutter
'''
      : '''
  test: ^1.24.0
''';

  File(p.join(pkgDir, 'pubspec.yaml')).writeAsStringSync('''
name: ${n.snake}
description: ${n.pascal} package.
version: 0.1.0
publish_to: none
resolution: workspace

environment:
  sdk: ">=3.11.0 <4.0.0"

dependencies:$coreBlock$flutterBlock

dev_dependencies:
$devTest
  very_good_analysis: ^9.0.0
''');

  File(p.join(pkgDir, 'README.md')).writeAsStringSync('''
# ${n.pascal}

## Usage

```dart
import 'package:${n.snake}/${n.snake}.dart';
```
''');

  File(p.join(pkgDir, 'CHANGELOG.md')).writeAsStringSync('''
## Unreleased

- Initial scaffold
''');

  File(p.join(pkgDir, 'test', '${n.snake}_test.dart')).writeAsStringSync('''
${flutter ? "import 'package:flutter_test/flutter_test.dart';" : "import 'package:test/test.dart';"}

void main() {
  test('placeholder', () {
    expect(true, isTrue);
  });
}
''');
}

void _registerPackage(Workspace ws, String name) {
  final rootPubspecPath = p.join(ws.root, 'pubspec.yaml');
  final entry = '  - packages/$name';

  final content = File(rootPubspecPath).readAsStringSync();
  if (content.contains('packages/$name')) return;
  final updated = content.replaceFirst('workspace:', 'workspace:\n$entry');
  File(rootPubspecPath).writeAsStringSync(updated);
}

void _appendPackageGuide(Workspace ws, _PackageNames n) {
  final guidePath = p.join(ws.root, 'docs', 'PACKAGE_GUIDE.md');
  if (!File(guidePath).existsSync()) return;
  final content = File(guidePath).readAsStringSync();
  final row = '| `${n.snake}` | ${n.pascal} package | Scaffolded |';
  if (content.contains('`${n.snake}`')) return;
  File(guidePath).writeAsStringSync('$content\n$row');
}
