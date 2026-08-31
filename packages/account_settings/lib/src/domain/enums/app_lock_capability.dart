/// Whether this device can perform local authentication at all.
///
/// Deliberately binary. The app lock runs with `biometricOnly: false`, and
/// `local_auth`'s device-support check is
/// `isDeviceSecure() || canAuthenticateWithBiometrics()` — so a device with a
/// PIN/pattern/password and **no enrolled biometric** can still satisfy the
/// gate via the device credential. "No fingerprint enrolled" is therefore not
/// a blocking state, and modelling it as one would wrongly refuse users who
/// only have a passcode.
enum AppLockCapability {
  /// The OS can authenticate the user — by biometric, device credential, or
  /// both.
  available,

  /// The device has no screen lock and no enrolled biometric, so there is
  /// nothing for the OS to check the user against.
  unsupported,
}
