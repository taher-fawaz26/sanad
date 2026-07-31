import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Logs HTTP requests and responses in debug mode.
///
/// **PII policy:** bodies on paths matching [sensitivePathFragments]
/// (`otp`, `password`, `verify`, `token`, `login`, `signin`, `signup`,
/// `register`, `refresh`) are redacted entirely. On non-sensitive paths,
/// keys matching [sensitiveKeys] are still redacted per-field so a stray
/// secret in an unrelated payload doesn't leak.
class LoggingInterceptor extends Interceptor {
  LoggingInterceptor({Logger? logger})
    : _logger = logger ?? Logger(printer: PrettyPrinter(methodCount: 0));

  final Logger _logger;

  static const _kMaxChars = 1200;

  /// Converts a [FormData] to a loggable map, showing field values and
  /// file metadata (filename + size) without reading binary content.
  static Map<String, dynamic> _formDataToMap(FormData fd) {
    final out = <String, dynamic>{};
    for (final entry in fd.fields) {
      out[entry.key] = entry.value;
    }
    for (final entry in fd.files) {
      out[entry.key] = '<file: ${entry.value.filename ?? 'unnamed'}>';
    }
    return out;
  }
  static const redactedMarker = '••• redacted •••';

  /// Case-insensitive path substrings that force full-body redaction.
  @visibleForTesting
  static const sensitivePathFragments = <String>[
    'otp',
    'password',
    'verify',
    'token',
    'login',
    'signin',
    'signup',
    'register',
    'refresh',
  ];

  /// Case-insensitive keys whose values are always redacted, on any path.
  /// Underscores and hyphens are stripped before comparison.
  @visibleForTesting
  static const sensitiveKeys = <String>{
    'password',
    'newpassword',
    'oldpassword',
    'currentpassword',
    'confirmpassword',
    'otp',
    'code',
    'token',
    'accesstoken',
    'refreshtoken',
    'authorization',
    'apikey',
    'secret',
    'pin',
  };

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      final sensitive = isSensitivePath(options.path);
      _logger.i('🌐 REQUEST[${options.method}] => ${options.path}');
      if (options.data != null) {
        _logger.d('📦 Body: ${preview(options.data, sensitive: sensitive)}');
      }
      if (options.queryParameters.isNotEmpty) {
        _logger.d(
          '❓ Query: ${preview(options.queryParameters, sensitive: sensitive)}',
        );
      }
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (kDebugMode) {
      final sensitive = isSensitivePath(response.requestOptions.path);
      _logger
        ..i(
          '✅ RESPONSE[${response.statusCode}]'
          ' => ${response.requestOptions.path}',
        )
        ..d('📄 Data: ${preview(response.data, sensitive: sensitive)}');
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      final sensitive = isSensitivePath(err.requestOptions.path);
      _logger
        ..e(
          '❌ ERROR[${err.response?.statusCode}]'
          ' => ${err.requestOptions.path}',
        )
        ..e('Message: ${err.message}');
      if (err.response?.data != null) {
        _logger.e('Data: ${preview(err.response?.data, sensitive: sensitive)}');
      }
    }
    super.onError(err, handler);
  }

  /// Returns whether [path] matches a sensitive fragment.
  static bool isSensitivePath(String path) {
    final lower = path.toLowerCase();
    for (final fragment in sensitivePathFragments) {
      if (lower.contains(fragment)) return true;
    }
    return false;
  }

  /// Returns a log-safe preview of [data]. On sensitive paths the whole
  /// value is replaced with [redactedMarker]. Otherwise, sensitive keys
  /// (nested inside maps and lists) are redacted individually, and the
  /// result is truncated to [_kMaxChars].
  static String preview(Object? data, {required bool sensitive}) {
    if (data == null) return 'null';
    if (sensitive) return redactedMarker;
    if (data is FormData) {
      return _truncate(jsonEncode(_redactMap(_formDataToMap(data))));
    }
    if (data is Map) {
      return _truncate(jsonEncode(_redactMap(data)));
    }
    if (data is List) {
      return _truncate(jsonEncode(data.map(_redactValue).toList()));
    }
    return _truncate(data.toString());
  }

  static Map<String, dynamic> _redactMap(Map<dynamic, dynamic> input) {
    final out = <String, dynamic>{};
    input.forEach((k, v) {
      final key = k.toString();
      if (_isSensitiveKey(key)) {
        out[key] = redactedMarker;
      } else {
        out[key] = _redactValue(v);
      }
    });
    return out;
  }

  static Object? _redactValue(Object? v) {
    if (v is Map) return _redactMap(v);
    if (v is List) return v.map(_redactValue).toList();
    return v;
  }

  static bool _isSensitiveKey(String key) {
    final normalized = key.toLowerCase().replaceAll(RegExp('[_\\-]'), '');
    return sensitiveKeys.contains(normalized);
  }

  static String _truncate(String s) {
    if (s.length <= _kMaxChars) return s;
    return '${s.substring(0, _kMaxChars)}… (${s.length} chars total)';
  }
}
