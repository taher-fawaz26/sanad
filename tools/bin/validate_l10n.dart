// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sanad_tools/workspace.dart';

/// Validates localization key parity between locale files.
void main() {
  final ws = Workspace.find();
  final base = p.join(ws.root, 'packages/localization/assets/translations');
  final enPath = p.join(base, 'en-US.json');
  final arPath = p.join(base, 'ar-AR.json');

  final enKeys = _flattenKeys(jsonDecode(File(enPath).readAsStringSync()) as Map<String, dynamic>);
  final arKeys = _flattenKeys(jsonDecode(File(arPath).readAsStringSync()) as Map<String, dynamic>);

  final missingInAr = enKeys.difference(arKeys);
  final missingInEn = arKeys.difference(enKeys);

  final violations = <String>[];
  for (final key in missingInAr) {
    violations.add('Missing in ar-AR: $key');
  }
  for (final key in missingInEn) {
    violations.add('Missing in en-US: $key');
  }

  if (violations.isEmpty) {
    print('✅ validate_l10n: ${enKeys.length} keys in sync');
    exit(0);
  }

  print('❌ validate_l10n: ${violations.length} violation(s):\n');
  for (final v in violations.take(50)) {
    print('  • $v');
  }
  if (violations.length > 50) {
    print('  ... and ${violations.length - 50} more');
  }
  exit(1);
}

Set<String> _flattenKeys(Map<String, dynamic> map, [String prefix = '']) {
  final keys = <String>{};
  for (final entry in map.entries) {
    final path = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
    if (entry.value is Map<String, dynamic>) {
      keys.addAll(_flattenKeys(entry.value as Map<String, dynamic>, path));
    } else {
      keys.add(path);
    }
  }
  return keys;
}
