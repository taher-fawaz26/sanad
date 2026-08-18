import 'package:dio/dio.dart';

/// Injects `Accept-Language: ar|en` on every outbound request.
///
/// Also sets `x-lang`, which some endpoints (e.g. locations/branches) read
/// instead of `Accept-Language` to pick the response language.
class AcceptLanguageInterceptor extends Interceptor {
  AcceptLanguageInterceptor({required String Function() resolveLanguageCode})
    : _resolve = resolveLanguageCode;

  final String Function() _resolve;
  static const _acceptLanguageHeader = 'Accept-Language';
  static const _langHeader = 'x-lang';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final raw = _resolve().toLowerCase();
    final language = (raw == 'en' || raw == 'ar') ? raw : 'ar';
    options.headers[_acceptLanguageHeader] = language;
    options.headers[_langHeader] = language;
    handler.next(options);
  }
}
