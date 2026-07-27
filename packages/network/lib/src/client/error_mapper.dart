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
          final meta = _coerceMap(data);
          // Prefer a structured error code sent by the backend over heuristics.
          // Backend should send {"errorCode": "ACCOUNT_UNVERIFIED"} for the
          // unverified-account case; migrate to this and remove the fallback
          // heuristic below once all API versions return a stable code.
          final rawCode =
              (meta?['errorCode'] ?? meta?['error_code'] ?? meta?['error'])
                  ?.toString()
                  .toUpperCase();
          if (rawCode == 'ACCOUNT_UNVERIFIED' ||
              rawCode == 'EMAIL_UNVERIFIED' ||
              rawCode == 'PHONE_UNVERIFIED') {
            return UnverifiedUserFailure(
              message: message,
              code: '403',
              metadata: meta,
            );
          }
          // Legacy heuristic: substring-match the message body while the
          // backend migration to structured error codes is in progress.
          final ml = message.toLowerCase();
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
          // Preserve the server's actual message (e.g. "Profile not found.")
          // so the UI can display something meaningful. Fall back to the
          // generic i18n key only when the response body contains nothing.
          return ServerFailure(
            message: message,
            code: '404',
            metadata: _coerceMap(data),
          );
        }
        if (statusCode == 409) {
          return ConflictFailure(
            message: message,
            code: '409',
            metadata: _coerceMap(data),
          );
        }
        if (statusCode == 429) {
          return RateLimitFailure(
            message: message,
            code: '429',
            metadata: _coerceMap(data),
          );
        }
        if (statusCode == 400 || statusCode == 422) {
          // Backend validation (NestJS class-validator) returns `message` as a
          // JSON array, or 422. Preserve every message rather than collapsing
          // to the first one, and surface it as a business ValidationFailure.
          final fieldErrors = _extractFieldErrors(data);
          final isValidation = _isValidationBody(data) ||
              statusCode == 422 ||
              fieldErrors != null;
          if (isValidation) {
            final messages = _extractMessages(data);
            return ValidationFailure(
              message: messages.isNotEmpty ? messages.first : message,
              messages: messages,
              fieldErrors: fieldErrors,
              code: statusCode!.toString(),
              metadata: _coerceMap(data),
            );
          }
          // A single-string 400 is a business-rule violation (e.g. "Cannot
          // delete the only branch"), not an input-validation error.
          return BusinessRuleFailure(
            message: message,
            code: statusCode!.toString(),
            metadata: _coerceMap(data),
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

  /// True when the response body carries a validation-shaped `message` (a JSON
  /// array). Business exceptions return `message` as a plain string instead.
  static bool _isValidationBody(dynamic data) {
    final map = _coerceMap(data);
    return map != null && map['message'] is List;
  }

  /// Extracts every validation message. Returns all entries of a `message`
  /// array, or a single-element list for a string body, or empty.
  static List<String> _extractMessages(dynamic data) {
    final map = _coerceMap(data);
    final raw = map?['message'];
    if (raw is List) {
      return raw
          .map((e) => e?.toString().trim() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    }
    final single = _extractMessage(data);
    return single == null ? const <String>[] : <String>[single];
  }

  /// Extracts field-scoped errors from an optional `errors` object
  /// (`{field: [messages]}`). Null when the backend provides no field mapping.
  static Map<String, List<String>>? _extractFieldErrors(dynamic data) {
    final map = _coerceMap(data);
    final raw = map?['errors'];
    if (raw is! Map) return null;
    final out = <String, List<String>>{};
    raw.forEach((key, value) {
      final list = value is List
          ? value.map((e) => e.toString()).toList()
          : <String>[value.toString()];
      if (list.isNotEmpty) out[key.toString()] = list;
    });
    return out.isEmpty ? null : out;
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
