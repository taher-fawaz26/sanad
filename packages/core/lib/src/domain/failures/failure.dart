import 'package:equatable/equatable.dart';

/// Base Failure class that all specific failures extend.
sealed class Failure extends Equatable {
  const Failure({required this.message, this.code, this.metadata});

  final String message;
  final String? code;
  final Map<String, dynamic>? metadata;

  @override
  List<Object?> get props => [message, code, metadata];

  @override
  String toString() =>
      'Failure(message: $message, code: $code, metadata: $metadata)';
}

// ─── Network & API Failures ────────────────────────────────────────────────

class NetworkFailure extends Failure {
  const NetworkFailure({required super.message, super.code, super.metadata});
}

class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.code, super.metadata});
}

class TimeoutFailure extends Failure {
  const TimeoutFailure({required super.message, super.code, super.metadata});
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({
    required super.message,
    super.code,
    super.metadata,
  });
}

class NoInternetFailure extends Failure {
  const NoInternetFailure({required super.message, super.code});
}

class UnknownFailure extends Failure {
  const UnknownFailure({required super.message, super.code, super.metadata});
}

class SecureConnectionFailure extends Failure {
  const SecureConnectionFailure({
    required super.message,
    super.code,
    super.metadata,
  });
}

// ─── Local & Cache Failures ────────────────────────────────────────────────

class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.code});
}

// ─── Business Failures ─────────────────────────────────────────────────────

class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, super.code, super.metadata});
}

/// The operation is blocked because the account has not yet been OTP-verified.
class UnverifiedUserFailure extends Failure {
  const UnverifiedUserFailure({
    required super.message,
    super.code,
    super.metadata,
  });
}

/// The operation is blocked because the user's role is insufficient.
class UnauthorizedRoleFailure extends Failure {
  const UnauthorizedRoleFailure({
    required super.message,
    super.code,
    super.metadata,
  });
}
