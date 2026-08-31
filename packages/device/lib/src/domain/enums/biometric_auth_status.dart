/// Outcome of a biometric authentication attempt.
enum BiometricAuthStatus {
  /// The user authenticated successfully.
  success,

  /// Authentication ran but did not succeed (wrong biometric, user failed).
  failed,

  /// The user cancelled the prompt.
  ///
  /// **Unreachable with the current `local_auth` backend.** The plugin
  /// defines no cancellation error code, so a dismissed prompt is reported
  /// identically to a failed match and arrives as [failed]. The value is kept
  /// so a future backend that *can* distinguish the two has somewhere to map
  /// it; do not branch on it expecting cancellations to land here.
  cancelled,

  /// Biometric hardware is unavailable or unsupported on this device.
  notAvailable,

  /// No biometrics are enrolled on the device.
  notEnrolled,

  /// Biometrics are temporarily or permanently locked out (too many attempts).
  lockedOut,

  /// The device has no passcode/PIN set, which biometrics require.
  passcodeNotSet,

  /// An unexpected platform error occurred.
  error,
}
