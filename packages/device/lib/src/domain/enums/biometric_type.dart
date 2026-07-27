/// Our own biometric-type model — `local_auth` types are never exposed.
enum BiometricType {
  /// Face-based biometrics (Face ID / face unlock).
  face,

  /// Fingerprint-based biometrics (Touch ID / fingerprint unlock).
  fingerprint,

  /// Iris-based biometrics.
  iris,

  /// A strong biometric class (Android) not otherwise categorised.
  strong,

  /// A weak biometric class (Android) not otherwise categorised.
  weak,
}
