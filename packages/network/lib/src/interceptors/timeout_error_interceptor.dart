import 'package:dio/dio.dart';
import 'package:network/network.dart' show ErrorMapper;
import 'package:network/src/client/error_mapper.dart' show ErrorMapper;

import 'package:network/src/exceptions/api_timeout_exception.dart';

/// Attaches [ApiTimeoutException] to Dio timeout errors so [ErrorMapper]
/// treats them uniformly regardless of which phase timed out.
class TimeoutErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (!_isTimeout(err) || err.error is ApiTimeoutException) {
      handler.next(err);
      return;
    }
    handler.next(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: ApiTimeoutException(phase: _phase(err.type)),
        message: err.message,
        stackTrace: err.stackTrace,
      ),
    );
  }

  static bool _isTimeout(DioException e) =>
      e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.sendTimeout ||
      e.type == DioExceptionType.receiveTimeout;

  static ApiTimeoutPhase? _phase(DioExceptionType t) => switch (t) {
    DioExceptionType.connectionTimeout => ApiTimeoutPhase.connect,
    DioExceptionType.sendTimeout => ApiTimeoutPhase.send,
    DioExceptionType.receiveTimeout => ApiTimeoutPhase.receive,
    _ => null,
  };
}
