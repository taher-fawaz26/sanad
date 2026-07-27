import 'package:device/src/domain/enums/biometric_auth_status.dart';
import 'package:equatable/equatable.dart';

/// Strongly-typed result of a biometric authentication attempt.
///
/// The service never throws platform exceptions into features; failures are
/// represented as a [status] instead.
class BiometricAuthResult extends Equatable {
  const BiometricAuthResult({
    required this.status,
    this.message,
  });

  /// Convenience constructor for a successful authentication.
  const BiometricAuthResult.success()
    : status = BiometricAuthStatus.success,
      message = null;

  final BiometricAuthStatus status;

  /// Optional diagnostic detail (never a raw platform stack trace).
  final String? message;

  bool get isSuccess => status == BiometricAuthStatus.success;

  @override
  List<Object?> get props => [status, message];
}
