# Release notes automation — extracts top CHANGELOG section for GitHub Release.

// ignore_for_file: avoid_print

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sanad_tools/workspace.dart';

void main(List<String> args) {
  final ws = Workspace.find();
  final changelog = File(p.join(ws.root, 'CHANGELOG.md'));
  if (!changelog.existsSync()) {
    print('CHANGELOG.md not found');
    exit(1);
  }

  final content = changelog.readAsStringSync();
  final section = _extractTopSection(content);
  final storeNotes = _truncate(section, 500);

  final outPath = args.isNotEmpty
      ? args.first
      : p.join(ws.root, 'build', 'release_notes.md');
  Directory(p.dirname(outPath)).createSync(recursive: true);
  File(outPath).writeAsStringSync('''$section

---
<!-- Store notes (500 char limit) -->
$storeNotes
''');

  print('✅ Release notes written to $outPath');
}

String _extractTopSection(String content) {
  final lines = content.split('\n');
  final buffer = StringBuffer();
  var capturing = false;

  for (final line in lines) {
    if (line.startsWith('## ')) {
      if (capturing) break;
      if (!line.toLowerCase().contains('unreleased')) {
        capturing = true;
      }
      if (capturing) buffer.writeln(line);
      continue;
    }
    if (capturing) buffer.writeln(line);
  }

  final result = buffer.toString().trim();
  return result.isEmpty ? content.trim() : result;
}

String _truncate(String text, int maxChars) {
  if (text.length <= maxChars) return text;
  return '${text.substring(0, maxChars - 3)}...';
}
