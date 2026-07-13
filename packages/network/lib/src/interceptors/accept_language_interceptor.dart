import 'package:dio/dio.dart';

/// Injects `Accept-Language: ar|en` on every outbound request.
class AcceptLanguageInterceptor extends Interceptor {
  AcceptLanguageInterceptor({required String Function() resolveLanguageCode})
    : _resolve = resolveLanguageCode;

  final String Function() _resolve;
  static const _header = 'Accept-Language';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final raw = _resolve().toLowerCase();
    options.headers[_header] = (raw == 'en' || raw == 'ar') ? raw : 'ar';
    handler.next(options);
  }
}
