import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Logs HTTP requests and responses in debug mode only.
///
/// Bodies are printed in full (debug builds). Disabled entirely in release.
class LoggingInterceptor extends Interceptor {
  LoggingInterceptor({Logger? logger})
    : _logger = logger ?? Logger(printer: PrettyPrinter(methodCount: 0));

  final Logger _logger;

  static const _kMaxChars = 4000;

  /// Converts a [FormData] to a loggable map, showing field values and
  /// file metadata (filename) without reading binary content.
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

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      _logger.i('🌐 REQUEST[${options.method}] => ${options.path}');
      if (options.data != null) {
        _logger.d('📦 Body: ${preview(options.data)}');
      }
      if (options.queryParameters.isNotEmpty) {
        _logger.d('❓ Query: ${preview(options.queryParameters)}');
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
      _logger
        ..i(
          '✅ RESPONSE[${response.statusCode}]'
          ' => ${response.requestOptions.path}',
        )
        ..d('📄 Data: ${preview(response.data)}');
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      _logger
        ..e(
          '❌ ERROR[${err.response?.statusCode}]'
          ' => ${err.requestOptions.path}',
        )
        ..e('Message: ${err.message}');
      if (err.response?.data != null) {
        _logger.e('Data: ${preview(err.response?.data)}');
      }
    }
    super.onError(err, handler);
  }

  /// Returns a readable preview of [data], truncated to [_kMaxChars].
  @visibleForTesting
  static String preview(Object? data) {
    if (data == null) return 'null';
    if (data is FormData) {
      return _truncate(jsonEncode(_formDataToMap(data)));
    }
    if (data is Map || data is List) {
      return _truncate(jsonEncode(data));
    }
    return _truncate(data.toString());
  }

  static String _truncate(String s) {
    if (s.length <= _kMaxChars) return s;
    return '${s.substring(0, _kMaxChars)}… (${s.length} chars total)';
  }
}
