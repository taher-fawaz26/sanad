// ignore_for_file: avoid_print

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sanad_tools/workspace.dart';

/// Developer environment health check for the Sanad platform.
void main(List<String> args) {
  final verbose = args.contains('--verbose');
  final ws = Workspace.find();
  final results = <_Check>[];

  results.add(_exec('Flutter SDK', 'flutter', ['--version']));
  results.add(_exec('Dart SDK', 'dart', ['--version']));
  results.add(_exec('Melos', 'melos', ['--version']));
  results.add(_exec('Git', 'git', ['--version']));

  final bootstrapFile = File(p.join(ws.root, '.dart_tool', 'package_config.json'));
  results.add(_Check(
    name: 'melos bootstrap',
    passed: bootstrapFile.existsSync(),
    message: bootstrapFile.existsSync()
        ? 'package_config.json present'
        : 'Run melos bootstrap',
  ));

  final packages = ws.discoverPackages();
  results.add(_Check(
    name: 'Workspace integrity',
    passed: packages.isNotEmpty,
    message: '${packages.length} packages parsed',
  ));

  results.add(_Check(
    name: 'dep_rules.yaml',
    passed: File(p.join(ws.root, 'dep_rules.yaml')).existsSync(),
    message: File(p.join(ws.root, 'dep_rules.yaml')).existsSync()
        ? 'present'
        : 'missing',
  ));

  final l10n = Process.runSync(
    'dart',
    ['run', 'bin/validate_l10n.dart'],
    workingDirectory: p.join(ws.root, 'tools'),
  );
  results.add(_Check(
    name: 'l10n',
    passed: l10n.exitCode == 0,
    message: l10n.exitCode == 0
        ? 'en-US and ar-AR keys match'
        : 'localization mismatches found',
    detail: verbose ? l10n.stdout.toString() : null,
  ));

  final moduleCount = _countModules(ws.root);
  results.add(_Check(
    name: 'Registered modules',
    passed: moduleCount > 0,
    message: '$moduleCount modules (auth, otp, forgot_password)',
  ));

  print('Sanad Doctor — platform health check\n');
  var warnings = 0;
  for (final check in results) {
    final icon = check.passed ? '✅' : '❌';
    print('$icon ${check.name} — ${check.message}');
    if (verbose && check.detail != null) {
      print('   ${check.detail}');
    }
    if (!check.passed) warnings++;
  }

  print('\n${warnings > 0 ? "$warnings issue(s)." : "All checks passed."} '
      'Run `melos doctor --verbose` for details.');
  exit(warnings > 0 ? 1 : 0);
}

_Check _exec(String name, String cmd, List<String> args) {
  try {
    final r = Process.runSync(cmd, args);
    final ok = r.exitCode == 0;
    final msg = r.stdout.toString().trim().split('\n').first;
    return _Check(name: name, passed: ok, message: msg.isEmpty ? cmd : msg);
  } on Object catch (e) {
    return _Check(name: name, passed: false, message: e.toString(), warning: true);
  }
}

int _countModules(String root) {
  for (final app in ['sanad_provider', 'sanad_client']) {
    final diFile =
        File(p.join(root, 'apps', app, 'lib', 'src', 'di', 'app_di.dart'));
    if (!diFile.existsSync()) continue;
    return 'Module()'.allMatches(diFile.readAsStringSync()).length;
  }
  return 0;
}

class _Check {
  _Check({
    required this.name,
    required this.passed,
    required this.message,
    this.detail,
    this.warning = false,
  });

  final String name;
  final bool passed;
  final String message;
  final String? detail;
  final bool warning;
}
