import 'dart:io' show Platform;

/// The `platform` value sent with a device-token registration.
///
/// The backend also accepts `WEB`, which these apps never send — a mobile
/// installation is one or the other.
enum DevicePlatform {
  ios('IOS'),
  android('ANDROID')
  ;

  const DevicePlatform(this.apiValue);

  final String apiValue;

  /// Resolves the running platform.
  ///
  /// Throws on anything that is not iOS or Android: push registration is a
  /// mobile-only concern and a silent wrong value would register a device that
  /// can never receive anything.
  static DevicePlatform current() {
    if (Platform.isIOS) return DevicePlatform.ios;
    if (Platform.isAndroid) return DevicePlatform.android;
    throw UnsupportedError(
      'Push registration is mobile-only; '
      '${Platform.operatingSystem} has no FCM platform value.',
    );
  }
}
