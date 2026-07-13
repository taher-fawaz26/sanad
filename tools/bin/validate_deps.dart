// ignore_for_file: avoid_print

import 'dart:io';

import 'package:sanad_tools/workspace.dart';
import 'package:yaml/yaml.dart';

/// Validates the workspace package dependency graph against dep_rules.yaml.
void main() {
  final ws = Workspace.find();
  final rules = ws.loadDepRules();
  final packages = ws.discoverPackages();
  final byName = {for (final pkg in packages) pkg.name: pkg};

  final violations = <String>[];

  final graph = <String, Set<String>>{
    for (final pkg in packages) pkg.name: pkg.dependencies,
  };

  try {
    topologicalSort(graph);
  } on FormatException catch (e) {
    violations.add('CYCLE: ${e.message}');
  }

  final forbidden = rules['forbidden_edges'] as YamlList? ?? YamlList();
  for (final pkg in packages) {
    for (final dep in pkg.dependencies) {
      final depPkg = byName[dep];

      for (final rule in forbidden) {
        final ruleMap = rule as YamlMap;
        final from = ruleMap['from']?.toString() ?? '';
        final to = ruleMap['to'];
        final reason = ruleMap['reason']?.toString() ?? 'forbidden edge';

        final fromMatches = from == '*' ||
            matchesPattern(pkg.name, from) ||
            matchesPattern(pkg.relativePath, from);

        if (!fromMatches) continue;

        final toList =
            to is YamlList ? to.map((e) => e.toString()).toList() : [to.toString()];
        for (final toPattern in toList) {
          final toMatches = matchesPattern(dep, toPattern) ||
              (depPkg != null && matchesPattern(depPkg.relativePath, toPattern));
          if (toMatches) {
            violations.add('FORBIDDEN: ${pkg.name} → $dep ($reason)');
          }
        }
      }
    }
  }

  final layers = rules['layer_order'] as YamlList? ?? YamlList();
  final tierMap = <String, int>{};
  for (var i = 0; i < layers.length; i++) {
    final pkgs = (layers[i] as YamlMap)['packages'] as YamlList? ?? YamlList();
    for (final pkg in pkgs) {
      tierMap[pkg.toString()] = i;
    }
  }

  for (final pkg in packages) {
    final fromTier = tierMap[pkg.name];
    if (fromTier == null) continue;
    for (final dep in pkg.dependencies) {
      final toTier = tierMap[dep];
      if (toTier == null) continue;
      if (fromTier < toTier) {
        violations.add(
          'TIER: ${pkg.name} (tier $fromTier) → $dep (tier $toTier)',
        );
      }
    }
  }

  for (final pkg in packages) {
    if (pkg.isApp) continue;
    for (final dep in pkg.dependencies) {
      if (byName[dep]?.isApp ?? false) {
        violations.add('APP_DEP: ${pkg.name} → app $dep');
      }
    }
  }

  if (violations.isEmpty) {
    print('✅ validate_deps: ${packages.length} packages — zero violations');
    exit(0);
  }

  print('❌ validate_deps: ${violations.length} violation(s):\n');
  for (final v in violations) {
    print('  • $v');
  }
  exit(1);
}
