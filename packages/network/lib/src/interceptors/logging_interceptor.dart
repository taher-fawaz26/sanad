import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Logs HTTP requests and responses in debug mode.
class LoggingInterceptor extends Interceptor {
  LoggingInterceptor({Logger? logger})
    : _logger = logger ?? Logger(printer: PrettyPrinter(methodCount: 0));

  final Logger _logger;
  static const _kMaxChars = 600;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      _logger.i('🌐 REQUEST[${options.method}] => ${options.path}');
      if (options.data != null) {
        _logger.d('📦 Body: ${_preview(options.data)}');
      }
      if (options.queryParameters.isNotEmpty) {
        _logger.d('❓ Query: ${options.queryParameters}');
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
        ..d('📄 Data: ${_preview(response.data)}');
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
        _logger.e('Data: ${_preview(err.response?.data)}');
      }
    }
    super.onError(err, handler);
  }

  String _preview(Object? data) {
    if (data == null) return 'null';
    final s = data is Map || data is List ? jsonEncode(data) : data.toString();
    if (s.length <= _kMaxChars) return s;
    return '${s.substring(0, _kMaxChars)}… (${s.length} chars total)';
  }
}
