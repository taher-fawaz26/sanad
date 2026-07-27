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

  BiometricAuthStatus _mapError(String code) {
    return switch (code) {
      auth_error.notAvailable => BiometricAuthStatus.notAvailable,
      auth_error.notEnrolled => BiometricAuthStatus.notEnrolled,
      auth_error.passcodeNotSet => BiometricAuthStatus.passcodeNotSet,
      auth_error.lockedOut ||
      auth_error.permanentlyLockedOut => BiometricAuthStatus.lockedOut,
      _ => BiometricAuthStatus.error,
    };
  }
}
