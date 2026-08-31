import 'package:device/src/domain/entities/biometric_auth_result.dart';
import 'package:device/src/domain/enums/biometric_auth_status.dart';
import 'package:device/src/domain/enums/biometric_type.dart' as domain;
import 'package:flutter/services.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:local_auth/local_auth.dart';

/// Wraps `local_auth`. No plugin type escapes this class; platform exceptions
/// are converted into a [BiometricAuthResult] rather than being rethrown.
class BiometricProvider {
  BiometricProvider([LocalAuthentication? auth])
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  Future<bool> isSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  Future<List<domain.BiometricType>> availableBiometrics() async {
    try {
      final types = await _auth.getAvailableBiometrics();
      return types.map(_mapType).toList();
    } on PlatformException {
      return const [];
    }
  }

  Future<BiometricAuthResult> authenticate({
    required String reason,
    bool biometricOnly = false,
  }) async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          biometricOnly: biometricOnly,
          stickyAuth: true,
        ),
      );
      return BiometricAuthResult(
        status: ok ? BiometricAuthStatus.success : BiometricAuthStatus.failed,
      );
    } on PlatformException catch (e) {
      return BiometricAuthResult(
        status: _mapError(e.code),
        message: e.message,
      );
    }
  }

  Future<void> cancel() async {
    try {
      await _auth.stopAuthentication();
    } on PlatformException {
      // Nothing actionable; cancellation is best-effort.
    }
  }

  domain.BiometricType _mapType(BiometricType type) {
    return switch (type) {
      BiometricType.face => domain.BiometricType.face,
      BiometricType.fingerprint => domain.BiometricType.fingerprint,
      BiometricType.iris => domain.BiometricType.iris,
      BiometricType.strong => domain.BiometricType.strong,
      BiometricType.weak => domain.BiometricType.weak,
    };
  }

  /// Maps a `local_auth` `PlatformException.code` onto a domain status.
  ///
  /// `local_auth` 2.3.0 defines no cancellation code (see
  /// `package:local_auth/error_codes.dart`): a user who dismisses the sheet
  /// and a user whose biometric simply does not match both surface as
  /// `authenticate() == false`, never as an exception. Cancellation is
  /// therefore not representable here, and
  /// [BiometricAuthStatus.cancelled] is unreachable by design — callers must
  /// treat [BiometricAuthStatus.failed] as "did not authenticate", without
  /// claiming to know why.
  BiometricAuthStatus _mapError(String code) {
    return switch (code) {
      auth_error.notAvailable ||
      // The OS itself cannot perform local authentication — indistinguishable
      // from missing hardware as far as any caller is concerned.
      auth_error.otherOperatingSystem => BiometricAuthStatus.notAvailable,
      auth_error.notEnrolled => BiometricAuthStatus.notEnrolled,
      auth_error.passcodeNotSet => BiometricAuthStatus.passcodeNotSet,
      auth_error.lockedOut ||
      auth_error.permanentlyLockedOut => BiometricAuthStatus.lockedOut,
      _ => BiometricAuthStatus.error,
    };
  }
}
