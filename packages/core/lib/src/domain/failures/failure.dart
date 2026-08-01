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

// ─── Location Failures ─────────────────────────────────────────────────────

class LocationFailure extends Failure {
  const LocationFailure({required super.message, super.code, super.metadata});
}

// ─── Local & Cache Failures ────────────────────────────────────────────────

class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.code});
}

// ─── Business Failures ─────────────────────────────────────────────────────

class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    this.messages = const <String>[],
    this.fieldErrors,
    super.code,
    super.metadata,
  });

  /// Every human-readable validation message returned by the backend.
  ///
  /// The base [message] holds the first line (a summary); this holds the full
  /// set. Backend validation (NestJS class-validator) returns `message` as a
  /// JSON array, so all entries are preserved rather than collapsed to one.
  final List<String> messages;

  /// Field-scoped errors (`{field: [messages]}`) when the backend provides
  /// them. Most validation responses use a flat [messages] list with no field
  /// mapping, in which case this is null.
  final Map<String, List<String>>? fieldErrors;

  @override
  List<Object?> get props => [...super.props, messages, fieldErrors];
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

class EmailNotValidFailure extends Failure {
  const EmailNotValidFailure({required super.message, super.code});
}

/// A business-rule violation reported by the backend (e.g. "Cannot delete the
/// only branch"). Distinct from input [ValidationFailure]: the input was
/// well-formed but the operation is not permitted in the current domain state.
class BusinessRuleFailure extends Failure {
  const BusinessRuleFailure({
    required super.message,
    super.code,
    super.metadata,
  });
}

/// The request conflicts with the current server state (HTTP 409), e.g. a
/// duplicate or a concurrent modification.
class ConflictFailure extends Failure {
  const ConflictFailure({required super.message, super.code, super.metadata});
}

/// Too many requests — the client is rate limited (HTTP 429). Retryable after
/// a backoff (honour `Retry-After` when present in [metadata]).
class RateLimitFailure extends Failure {
  const RateLimitFailure({required super.message, super.code, super.metadata});
}
