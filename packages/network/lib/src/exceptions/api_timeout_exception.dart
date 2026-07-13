import 'package:core/core.dart' show TimeoutFailure;
import 'package:network/network.dart' show ErrorMapper;
import 'package:network/src/client/error_mapper.dart' show ErrorMapper;

/// Thrown when an HTTP request exceeds connect, send, or receive limits.
/// [ErrorMapper] converts it to [TimeoutFailure].
class ApiTimeoutException implements Exception {
  const ApiTimeoutException({this.phase});

  final ApiTimeoutPhase? phase;

  @override
  String toString() => 'ApiTimeoutException(phase: $phase)';
}

enum ApiTimeoutPhase { connect, send, receive }
