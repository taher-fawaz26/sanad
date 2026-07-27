import 'package:core/core.dart';
import 'package:device/src/config/device_config.dart';
import 'package:device/src/domain/entities/app_info_data.dart';
import 'package:device/src/domain/entities/biometric_auth_result.dart';
import 'package:device/src/domain/entities/device_info_data.dart';
import 'package:device/src/domain/entities/share_result.dart';
import 'package:device/src/domain/enums/biometric_type.dart';
import 'package:device/src/domain/enums/connectivity_status.dart';
import 'package:device/src/domain/services/app_info_service.dart';
import 'package:device/src/domain/services/biometric_service.dart';
import 'package:device/src/domain/services/clipboard_service.dart';
import 'package:device/src/domain/services/connectivity_service.dart';
import 'package:device/src/domain/services/device_info_service.dart';
import 'package:device/src/domain/services/share_service.dart';
import 'package:device/src/domain/services/url_launcher_service.dart';

/// Static façade over every device capability.
///
/// This is the public API that features use. Features never instantiate
/// services directly — they call methods on this class after [DeviceModule]
/// has registered the DI bindings at bootstrap.
///
/// ```dart
/// final info = await Device.info();
/// final online = await Device.isConnected();
/// await Device.copy('hello');
/// await Device.openUrl('https://example.com');
/// ```
abstract final class Device {
  Device._();

  static DeviceInfoService get _deviceInfo => sl<DeviceInfoService>();
  static AppInfoService get _appInfo => sl<AppInfoService>();
  static ConnectivityService get _connectivity => sl<ConnectivityService>();
  static BiometricService get _biometrics => sl<BiometricService>();
  static ClipboardService get _clipboard => sl<ClipboardService>();
  static ShareService get _share => sl<ShareService>();
  static UrlLauncherService get _url => sl<UrlLauncherService>();

  /// The active [DeviceConfig].
  static DeviceConfig get config {
    if (sl.isRegistered<DeviceConfig>()) return sl<DeviceConfig>();
    return const DeviceConfig();
  }

  // --- Device & app info -----------------------------------------------------

  /// A snapshot of the physical device.
  static Future<DeviceInfoData> info() => _deviceInfo.getDeviceInfo();

  /// A snapshot of the running app bundle.
  static Future<AppInfoData> appInfo() => _appInfo.getAppInfo();

  // --- Connectivity ----------------------------------------------------------

  /// The current connectivity status.
  static Future<ConnectivityStatus> connectivityStatus() =>
      _connectivity.currentStatus();

  /// Whether the device currently has any active connection.
  static Future<bool> isConnected() => _connectivity.isConnected();

  /// Stream of connectivity changes.
  static Stream<ConnectivityStatus> onConnectivityChanged() =>
      _connectivity.onStatusChanged();

  // --- Biometrics ------------------------------------------------------------

  /// Whether the device supports biometric authentication.
  static Future<bool> isBiometricSupported() => _biometrics.isSupported();

  /// The biometric methods available on this device.
  static Future<List<BiometricType>> availableBiometrics() =>
      _biometrics.availableBiometrics();

  /// Prompts the user to authenticate with biometrics.
  ///
  /// When [reason] is omitted, [DeviceConfig.defaultBiometricReason] is used.
  static Future<BiometricAuthResult> authenticate({
    String? reason,
    bool? biometricOnly,
  }) => _biometrics.authenticate(
    reason: reason ?? config.defaultBiometricReason,
    biometricOnly: biometricOnly ?? config.biometricOnlyByDefault,
  );

  /// Cancels an in-flight biometric prompt.
  static Future<void> cancelAuthentication() => _biometrics.cancel();

  // --- Clipboard -------------------------------------------------------------

  /// Copies [text] to the clipboard.
  static Future<void> copy(String text) => _clipboard.copy(text);

  /// Returns the plain-text clipboard contents, or `null` if empty.
  static Future<String?> paste() => _clipboard.paste();

  /// Clears the clipboard.
  static Future<void> clearClipboard() => _clipboard.clear();

  /// Whether the clipboard holds plain-text data.
  static Future<bool> clipboardHasData() => _clipboard.hasData();

  // --- Share -----------------------------------------------------------------

  /// Shares plain [text] via the system share sheet.
  static Future<ShareResult> shareText(String text, {String? subject}) =>
      _share.shareText(text, subject: subject);

  /// Shares files by absolute [paths].
  static Future<ShareResult> shareFiles(List<String> paths, {String? text}) =>
      _share.shareFiles(paths, text: text);

  /// Shares a [uri] link.
  static Future<ShareResult> shareUri(String uri) => _share.shareUri(uri);

  // --- URL launcher ----------------------------------------------------------

  /// Opens [url] in the platform browser / default handler.
  static Future<bool> openUrl(String url) => _url.openUrl(url);

  /// Opens the dialer for [phoneNumber].
  static Future<bool> openPhone(String phoneNumber) =>
      _url.openPhone(phoneNumber);

  /// Opens the mail composer to [email].
  static Future<bool> openEmail(
    String email, {
    String? subject,
    String? body,
  }) => _url.openEmail(email, subject: subject, body: body);

  /// Opens the SMS composer to [phoneNumber].
  static Future<bool> openSms(String phoneNumber, {String? body}) =>
      _url.openSms(phoneNumber, body: body);

  /// Opens the maps app at [query] (address or "lat,lng").
  static Future<bool> openMaps(String query) => _url.openMaps(query);
}
