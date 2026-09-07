import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Enforces the SAN-774 invariant that made the two-store desync impossible:
/// `AppLocaleSync` is the only place that applies a locale to
/// EasyLocalization, and `saveLocale` is never re-enabled.
///
/// Written as a test rather than a doc line because the old bug was three
/// hand-synced call sites, each one line away from drifting again. `.cursor`'s
/// localization rule already said "never call `context.setLocale()` directly
/// in widgets" — and the codebase violated it in three places.
void main() {
  late Directory repoRoot;

  setUpAll(() {
    // The test runs from the package directory.
    repoRoot = Directory.current.parent.parent;
    expect(
      Directory('${repoRoot.path}/packages').existsSync(),
      isTrue,
      reason: 'expected to locate the repo root, got ${repoRoot.path}',
    );
  });

  Iterable<File> libDartFiles() =>
      [
        Directory('${repoRoot.path}/packages'),
        Directory('${repoRoot.path}/apps'),
      ].expand(
        (dir) => dir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))
            // Source only: tests legitimately stub the apply
            // step, and generated trees are not ours.
            .where(
              (f) =>
                  f.path.contains(
                    '${Platform.pathSeparator}lib'
                    '${Platform.pathSeparator}',
                  ) &&
                  !f.path.contains(
                    '${Platform.pathSeparator}.dart_tool'
                    '${Platform.pathSeparator}',
                  ),
            ),
      );

  /// Source lines only — a doc comment that *names* `setLocale` (as the
  /// `setAppLanguage` docs do, to say not to call it) is not a call site.
  String codeOf(File file) => file
      .readAsLinesSync()
      .where((line) => !line.trimLeft().startsWith('//'))
      .join('\n');

  test('setLocale is called from exactly one file', () {
    final callers = libDartFiles()
        .where((f) => codeOf(f).contains('setLocale('))
        .map((f) => f.uri.pathSegments.last)
        .toSet();

    expect(
      callers,
      {'app_locale_sync.dart'},
      reason:
          'switch the language with `context.setAppLanguage` instead; '
          'AppLocaleSync owns the EasyLocalization side',
    );
  });

  test('no source file re-enables EasyLocalization locale persistence', () {
    // `saveLocale: true` restores a second persisted locale store, which is
    // what allowed the UI locale and the API language to disagree across
    // restarts.
    final offenders = libDartFiles()
        .where((f) => codeOf(f).contains('saveLocale: true'))
        .map((f) => f.path)
        .toList();

    expect(offenders, isEmpty);
  });
}
