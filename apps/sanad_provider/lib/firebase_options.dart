// GENERATED FILE — do not edit manually.
//
// Run the following command from apps/sanad_provider/ to generate this file
// with your real Firebase project configuration:
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// flutterfire configure will overwrite this stub automatically.

// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'Run `flutterfire configure` from apps/sanad_provider/ to populate '
          'this file with your Firebase project options.',
        );
    }
  }

  // TODO: replace with real values after running `flutterfire configure`
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'TODO',
    appId: 'TODO',
    messagingSenderId: 'TODO',
    projectId: 'TODO',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBLRKfvc4vGnsz3XRVmUuL0ANheygJHZ2o',
    appId: '1:53289695434:android:e02721f6ca935b09bd1c33',
    messagingSenderId: '53289695434',
    projectId: 'sanad-da77a',
    storageBucket: 'sanad-da77a.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDAZq0xQv8-YQc4uSX77-2Qz41qhcCl5UE',
    appId: '1:53289695434:ios:93f93071b005c793bd1c33',
    messagingSenderId: '53289695434',
    projectId: 'sanad-da77a',
    storageBucket: 'sanad-da77a.firebasestorage.app',
    iosClientId:
        '53289695434-r5ne08frculv1k1e6uncpiovuakf0tff.apps.googleusercontent.com',
    iosBundleId: 'com.sanad.provider',
  );
}
