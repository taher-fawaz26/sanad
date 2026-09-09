import 'package:notifications/src/domain/enums/device_platform.dart';

/// `RegisterDeviceDto` — the body of `POST notifications/devices`.
class RegisterDeviceRequest {
  const RegisterDeviceRequest({required this.token, required this.platform});

  /// The FCM registration token for this installation.
  final String token;

  final DevicePlatform platform;

  Map<String, dynamic> toJson() => {
    'token': token,
    'platform': platform.apiValue,
  };
}
