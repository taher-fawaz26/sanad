import 'package:device/src/domain/entities/biometric_auth_result.dart';
import 'package:device/src/domain/enums/biometric_type.dart';

/// Performs local biometric authentication.
abstract class BiometricService {
  /// Whether the device supports and can currently check biometrics.
  Future<bool> isSupported();

  /// The biometric methods enrolled/available on this device.
  Future<List<BiometricType>> availableBiometrics();

  /// Prompts the user to authenticate.
  ///
  /// [reason] is the localized message shown in the system prompt.
  /// When [biometricOnly] is true, device PIN/password fallback is disabled.
  Future<BiometricAuthResult> authenticate({
    required String reason,
    bool biometricOnly = false,
  });

  /// Cancels an in-flight authentication prompt, if any.
  Future<void> cancel();
}
