@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Build-level regression guard for SAN-823.
///
/// The Maps key has two consumers that read it from different places: the
/// native Google Maps SDK reads the `MAPS_API_KEY` manifest placeholder, while
/// the Dart Maps REST calls (Google `place_id` resolution + Places
/// autocomplete) read the `MAPS_API_KEY` *dart-define* through
/// `String.fromEnvironment` in `lib/src/di/app_di.dart`.
///
/// Before SAN-823 only `.vscode/launch.json` and the `build:provider:*` melos
/// scripts supplied that dart-define, so a bare `flutter build apk --release`
/// produced an APK whose map rendered and whose pin reverse-geocoded (keyless
/// platform geocoder) but which could never resolve a `place_id` — Branch
/// Location was permanently unconfirmable and Places search silently inert.
///
/// `android/app/build.gradle.kts` now derives the dart-define from the same
/// `local.properties` entry the manifest placeholder uses. These tests fail if
/// either half of that single-source-of-truth wiring is removed.
void main() {
  late String gradle;

  setUpAll(() {
    final file = File('android/app/build.gradle.kts');
    expect(
      file.existsSync(),
      isTrue,
      reason: 'Run this test from apps/sanad_provider.',
    );
    gradle = file.readAsStringSync();
  });

  group('sanad_provider Android build config', () {
    test('still feeds MAPS_API_KEY to the native manifest placeholder', () {
      expect(
        gradle,
        contains('manifestPlaceholders["MAPS_API_KEY"]'),
        reason:
            'Without the placeholder the native Maps SDK gets no key and the '
            'map picker renders a blank background (SAN-598).',
      );
      expect(gradle, contains('localProperties.getProperty("MAPS_API_KEY"'));
    });

    test('derives the Dart MAPS_API_KEY dart-define from local.properties', () {
      expect(
        gradle,
        contains('"dart-defines"'),
        reason:
            'Gradle must inject the MAPS_API_KEY dart-define so that ANY build '
            'command — including a bare `flutter build apk --release` — can '
            'resolve a Google place_id. Removing this reintroduces SAN-823.',
      );
      expect(
        gradle,
        contains(r'"MAPS_API_KEY=$mapsApiKey"'),
        reason: 'The injected define must carry the local.properties value.',
      );
      expect(
        gradle,
        contains('Base64.getEncoder()'),
        reason: 'Flutter expects dart-defines base64-encoded.',
      );
    });

    test('lets an explicit command-line dart-define win', () {
      expect(
        gradle,
        contains('alreadyProvided'),
        reason:
            'The melos scripts and the CI workflow pass '
            '--dart-define-from-file; Gradle must not clobber it.',
      );
      expect(gradle, contains('Base64.getDecoder()'));
    });

    test('warns instead of silently shipping a keyless build', () {
      expect(gradle, contains('logger.warn'));
      expect(gradle, contains('MAPS_API_KEY'));
    });
  });
}
