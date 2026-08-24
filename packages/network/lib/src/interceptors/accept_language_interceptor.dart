import 'package:dio/dio.dart';

/// Injects `Accept-Language: ar|en` on every outbound request.
///
/// Also sets `x-lang`, which some endpoints (e.g. locations/branches) read
/// instead of `Accept-Language` to pick the response language.
///
/// Headers only — never a `lang` query parameter. The verified Services
/// Module API contract (Confluence `45416482`) documents each list
/// endpoint's allowed query params explicitly (`page`/`limit`/`search`/
/// `status`/`categoryId`, depending on the endpoint) and `lang` is not among
/// them anywhere; `provider-services` and `service-requests` both 400 with
/// `"property lang should not exist"` if it's sent. A prior fix attempt
/// added a global `lang` query param to work around SAN-579 (catalog
/// service names showing in English under an Arabic UI) and caused that
/// exact regression — reverted. Per the same contract, service names are
/// deliberately never translated — only the nested category's `name` and
/// `description` are, via `x-lang` — so SAN-579's "fix" was targeting
/// intended backend behavior, not a bug.
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
