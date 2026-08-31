import 'package:equatable/equatable.dart';

/// App-wide configuration for the device package.
///
/// Kept intentionally small and future-proof — new capability settings can be
/// added here without breaking the public API.
class DeviceConfig extends Equatable {
  const DeviceConfig({
    this.defaultBiometricReason = 'Please authenticate to continue',
    this.biometricOnlyByDefault = false,
  });

  /// Fallback reason shown in the biometric prompt when a caller does not
  /// supply one.
  ///
  /// This default is a plain English literal and is **not** localized: this
  /// package sits below the localization layer and must stay
  /// UI-framework-agnostic. Production call sites are expected to pass an
  /// explicit, already-translated `reason` to
  /// `Device.authenticate(reason: ...)`, so this value should never reach a
  /// user.
  final String defaultBiometricReason;

  /// Whether biometric authentication disables device PIN/password fallback by
  /// default.
  final bool biometricOnlyByDefault;

  @override
  List<Object?> get props => [defaultBiometricReason, biometricOnlyByDefault];
}
