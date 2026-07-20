// ignore_for_file: avoid_print

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sanad_tools/workspace.dart';
import 'package:yaml/yaml.dart';

/// Scans Dart imports for architectural violations.
void main() {
  final ws = Workspace.find();
  final rules = ws.loadDepRules();
  final packages = ws.discoverPackages();

  final violations = <String>[];
  final deletedPackages =
      (rules['deleted_packages'] as YamlList? ?? YamlList()).map((e) => e.toString()).toSet();
  final layerRules = rules['layer_rules'] as YamlMap? ?? YamlMap();
  final dioAllowed =
      (rules['dio_allowed_packages'] as YamlList? ?? YamlList()).map((e) => e.toString()).toSet();

  for (final pkg in packages) {
    final libDir = Directory(p.join(pkg.absolutePath, 'lib'));
    if (!libDir.existsSync()) continue;

    for (final entity in libDir.listSync(recursive: true, followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final relFile = p.relative(entity.path, from: pkg.absolutePath).replaceAll('\\', '/');
      final lines = entity.readAsLinesSync();

      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (!line.startsWith('import ') && !line.startsWith('export ')) continue;

        final importPath = _extractImportPath(line);
        if (importPath == null) continue;

        for (final deleted in deletedPackages) {
          if (importPath.contains('package:$deleted/')) {
            violations.add('${pkg.name}/$relFile:${i + 1} — deleted package $deleted');
          }
        }

        if (importPath.contains('package:dio/') && !dioAllowed.contains(pkg.name)) {
          violations.add('${pkg.name}/$relFile:${i + 1} — Dio outside network package');
        }

        final srcMatch = RegExp(r'package:([a-z_]+)/src/').firstMatch(importPath);
        if (srcMatch != null && srcMatch.group(1) != pkg.name) {
          violations.add('${pkg.name}/$relFile:${i + 1} — src bypass: $importPath');
        }

        if (relFile.contains('lib/src/domain/')) {
          _checkLayer(pkg.name, relFile, i + 1, importPath,
              layerRules['domain'] as YamlMap?, violations);
        }
        if (relFile.contains('lib/src/data/')) {
          _checkLayer(pkg.name, relFile, i + 1, importPath,
              layerRules['data'] as YamlMap?, violations);
        }
      }
    }
  }

  if (violations.isEmpty) {
    print('✅ scan_imports: zero violations');
    exit(0);
  }

  print('❌ scan_imports: ${violations.length} violation(s):\n');
  for (final v in violations) {
    print('  • $v');
  }
  exit(1);
}

String? _extractImportPath(String line) {
  final match = RegExp(r'''(?:import|export)\s+['"]([^'"]+)['"]''').firstMatch(line);
  return match?.group(1);
}

void _checkLayer(
  String pkgName,
  String relFile,
  int line,
  String importPath,
  YamlMap? layerConfig,
  List<String> violations,
) {
  if (layerConfig == null) return;
  final patterns = (layerConfig['forbidden_import_patterns'] as YamlList? ?? YamlList())
      .map((e) => e.toString());

  for (final pattern in patterns) {
    if (importPath.contains(pattern)) {
      violations.add('$pkgName/$relFile:$line — layer: $importPath');
    }
  }
}
