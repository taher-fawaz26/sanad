import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// Shared workspace utilities for Sanad tooling scripts.
class Workspace {
  Workspace(this.root);

  final String root;

  /// Finds the workspace root by walking up from the current directory
  /// looking for a root `pubspec.yaml` with a `workspace:` key.
  ///
  /// Melos 7.x has no standalone `melos.yaml` file — the workspace root is
  /// defined solely by the native Dart pub workspace list in `pubspec.yaml`.
  static Workspace find() {
    var dir = Directory.current;
    while (true) {
      final pubspecFile = File(p.join(dir.path, 'pubspec.yaml'));
      if (pubspecFile.existsSync()) {
        final doc = loadYaml(pubspecFile.readAsStringSync());
        if (doc is YamlMap && doc.containsKey('workspace')) {
          return Workspace(dir.path);
        }
      }
      final parent = dir.parent;
      if (parent.path == dir.path) {
        throw StateError(
          'Could not find a workspace root pubspec.yaml (with a `workspace:` '
          'key) from ${Directory.current.path}',
        );
      }
      dir = parent;
    }
  }

  List<PackageInfo> discoverPackages() {
    final rootPubspec = File(p.join(root, 'pubspec.yaml'));
    final doc = loadYaml(rootPubspec.readAsStringSync()) as YamlMap;
    final workspace = doc['workspace'] as YamlList? ?? YamlList();
    final packages = <PackageInfo>[];

    for (final entry in workspace) {
      final rel = entry.toString();
      final pubspecPath = p.join(root, rel, 'pubspec.yaml');
      if (!File(pubspecPath).existsSync()) continue;
      packages.add(PackageInfo.fromPubspec(root, rel, pubspecPath));
    }
    return packages;
  }

  YamlMap loadDepRules() {
    final file = File(p.join(root, 'dep_rules.yaml'));
    if (!file.existsSync()) {
      throw StateError('dep_rules.yaml not found at ${file.path}');
    }
    return loadYaml(file.readAsStringSync()) as YamlMap;
  }
}

class PackageInfo {
  PackageInfo({
    required this.name,
    required this.relativePath,
    required this.absolutePath,
    required this.dependencies,
  });

  final String name;
  final String relativePath;
  final String absolutePath;
  final Set<String> dependencies;

  static PackageInfo fromPubspec(String root, String rel, String pubspecPath) {
    final doc = loadYaml(File(pubspecPath).readAsStringSync()) as YamlMap;
    final name = doc['name']?.toString() ?? p.basename(rel);
    final deps = <String>{};

    for (final section in ['dependencies', 'dev_dependencies']) {
      final map = doc[section] as YamlMap?;
      if (map == null) continue;
      for (final key in map.keys) {
        final dep = key.toString();
        if (dep == 'flutter' || dep == 'sdk') continue;
        final value = map[key];
        if (value is YamlMap && value.containsKey('path')) {
          deps.add(dep);
        } else if (value is String || value is YamlMap) {
          // Hosted/SDK deps — not workspace packages
        }
      }
    }

    return PackageInfo(
      name: name,
      relativePath: rel.replaceAll('\\', '/'),
      absolutePath: p.join(root, rel),
      dependencies: deps,
    );
  }

  /// True only for the app root itself (e.g. `apps/sanad_provider`), not for
  /// app-local packages nested under it (e.g. `apps/sanad_provider/packages/branches`).
  bool get isApp =>
      relativePath.startsWith('apps/') && relativePath.split('/').length == 2;
}

List<String> topologicalSort(Map<String, Set<String>> graph) {
  final visited = <String>{};
  final stack = <String>{};
  final order = <String>[];
  String? cycleNode;

  void visit(String node) {
    if (stack.contains(node)) {
      cycleNode = node;
      return;
    }
    if (visited.contains(node)) return;
    stack.add(node);
    for (final dep in graph[node] ?? <String>{}) {
      visit(dep);
      if (cycleNode != null) return;
    }
    stack.remove(node);
    visited.add(node);
    order.add(node);
  }

  for (final node in graph.keys) {
    visit(node);
    if (cycleNode != null) break;
  }

  if (cycleNode != null) {
    throw FormatException('Circular dependency detected involving $cycleNode');
  }

  return order;
}

int? tierOf(String packageName, YamlMap rules) {
  final layers = rules['layer_order'] as YamlList? ?? YamlList();
  for (var i = 0; i < layers.length; i++) {
    final layer = layers[i] as YamlMap;
    final pkgs = layer['packages'] as YamlList? ?? YamlList();
    for (final pkg in pkgs) {
      if (pkg.toString() == packageName) return i;
    }
  }
  return null;
}

bool matchesPattern(String value, String pattern) {
  if (pattern == '*') return true;
  if (pattern.endsWith('/**')) {
    final prefix = pattern.substring(0, pattern.length - 3);
    return value.startsWith(prefix);
  }
  if (pattern.contains('*')) {
    final regex = RegExp('^${pattern.replaceAll('*', '.*')}\$');
    return regex.hasMatch(value);
  }
  return value == pattern;
}
