import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:network/src/exceptions/api_timeout_exception.dart';
import 'package:network/src/messages/error_messages.dart';
import 'package:network/src/ssl/secure_transport_exceptions.dart';

/// Maps third-party exceptions (Dio, SocketException) to domain [Failure]s.
/// No Dio types ever leak past this class.
class ApiException implements Exception {
  const ApiException(this.message, {this.code, this.metadata});
  final String message;
  final String? code;
  final Map<String, dynamic>? metadata;
}

abstract final class ErrorMapper {
  ErrorMapper._();

  static Failure mapError(Object error) {
    if (error is ApiTimeoutException) return _fromApiTimeout(error);
    if (error is DioException) return _fromDio(error);
    if (error is SocketException) {
      return const NoInternetFailure(message: ErrorMessages.noInternet);
    }
    if (error is TimeoutException) {
      return const TimeoutFailure(message: ErrorMessages.timeout);
    }
    if (error is ApiException) {
      return ServerFailure(
        message: error.message,
        code: error.code,
        metadata: error.metadata,
      );
    }
    return UnknownFailure(
      message: ErrorMessages.unknown,
      code: 'unknown',
      metadata: {
        'error_type': error.runtimeType.toString(),
        'detail': error.toString(),
      },
    );
  }

  static Failure _fromApiTimeout(ApiTimeoutException e) => TimeoutFailure(
    message: ErrorMessages.timeout,
    code: 'timeout',
    metadata: e.phase != null ? {'phase': e.phase!.name} : null,
  );

  static Failure _fromDio(DioException e) {
    final inner = e.error;

    if (inner is ApiTimeoutException) return _fromApiTimeout(inner);
    if (inner is TlsPinningRejectedException ||
        inner is CertificateValidationFailedException ||
        inner is UnexpectedTransportSecurityException) {
      return const SecureConnectionFailure(
        message: ErrorMessages.secureConnectionFailed,
        code: 'secure_connection',
      );
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const TimeoutFailure(
          message: ErrorMessages.timeout,
          code: 'timeout',
        );

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final data = e.response?.data;
        final message =
            _extractMessage(data) ?? ErrorMessages.serverError;
        if (statusCode == 401) {
          return UnauthorizedFailure(message: message, code: '401');
        }
        if (statusCode == 403) {
          final ml = message.toLowerCase();
          final meta = _coerceMap(data);
          final looksUnverified = ml.contains('verif') ||
              ml.contains('unverified') ||
              (ml.contains('email') && ml.contains('confirm')) ||
              (ml.contains('pending') && ml.contains('verification'));
          if (looksUnverified) {
            return UnverifiedUserFailure(
              message: message,
              code: '403',
              metadata: meta,
            );
          }
          return UnauthorizedRoleFailure(
            message: message,
            code: '403',
            metadata: meta,
          );
        }
        if (statusCode == 404) {
          return const ServerFailure(
            message: ErrorMessages.notFound,
            code: '404',
          );
        }
        if (statusCode != null && statusCode >= 500) {
          return ServerFailure(message: message, code: statusCode.toString());
        }
        return ServerFailure(
          message: message,
          code: statusCode?.toString(),
          metadata: _coerceMap(data),
        );

      case DioExceptionType.cancel:
        return const NetworkFailure(message: ErrorMessages.requestCancelled);

      case DioExceptionType.connectionError:
        return const NoInternetFailure(message: ErrorMessages.noInternet);

      case DioExceptionType.badCertificate:
        if (inner is TlsPinningRejectedException ||
            inner is CertificateValidationFailedException) {
          return const SecureConnectionFailure(
            message: ErrorMessages.secureConnectionFailed,
            code: 'secure_connection',
          );
        }
        if (inner is SocketException) {
          return const NoInternetFailure(message: ErrorMessages.noInternet);
        }
        return const SecureConnectionFailure(
          message: ErrorMessages.secureConnectionFailed,
          code: 'secure_connection',
        );

      case DioExceptionType.unknown:
        if (inner is SocketException) {
          return const NoInternetFailure(message: ErrorMessages.noInternet);
        }
        if (inner is TimeoutException) {
          return const TimeoutFailure(message: ErrorMessages.timeout);
        }
        return UnknownFailure(
          message: ErrorMessages.unknown,
          code: 'unknown',
          metadata: {'dio_error': e.message},
        );
    }
  }

  static String? _extractMessage(dynamic data) {
    if (data is String) {
      final t = data.trim();
      return t.isEmpty ? null : t;
    }
    final map = _coerceMap(data);
    if (map == null) return null;
    for (final key in [
      'message',
      'detail',
      'error',
      'errorMessage',
      'reason',
    ]) {
      final v = _flattenField(map[key]);
      if (v != null) return v;
    }
    return null;
  }

  static String? _flattenField(dynamic raw) {
    if (raw == null) return null;
    if (raw is String) {
      final t = raw.trim();
      return t.isEmpty ? null : t;
    }
    if (raw is List) {
      if (raw.isEmpty) return null;
      final first = raw.first;
      if (first is Map) {
        final m = Map<String, dynamic>.from(first);
        return _flattenField(m['message']) ??
          _flattenField(m['msg']) ??
          first.toString();
      }
      return first.toString();
    }
    if (raw is Map) {
      final m = Map<String, dynamic>.from(raw);
      return _flattenField(m['message']) ??
          _flattenField(m['msg']) ??
          raw.toString();
    }
    final s = raw.toString().trim();
    return s.isEmpty ? null : s;
  }

  static Map<String, dynamic>? _coerceMap(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      try {
        return Map<String, dynamic>.from(data);
      } on Object catch (_) {
        return null;
      }
    }
    return null;
  }
}
