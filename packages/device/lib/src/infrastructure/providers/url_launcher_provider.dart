import 'package:url_launcher/url_launcher.dart';

/// Wraps `url_launcher`. No plugin type escapes this class.
class UrlLauncherProvider {
  const UrlLauncherProvider();

  Future<bool> openUrl(String url) => _launch(Uri.parse(url), external: true);

  Future<bool> openPhone(String phoneNumber) =>
      _launch(Uri(scheme: 'tel', path: phoneNumber));

  Future<bool> openEmail(String email, {String? subject, String? body}) {
    final query = <String, String>{
      if (subject != null) 'subject': subject,
      if (body != null) 'body': body,
    };
    return _launch(
      Uri(
        scheme: 'mailto',
        path: email,
        query: query.isEmpty ? null : _encodeQuery(query),
      ),
    );
  }

  Future<bool> openSms(String phoneNumber, {String? body}) {
    return _launch(
      Uri(
        scheme: 'sms',
        path: phoneNumber,
        query: body == null ? null : _encodeQuery({'body': body}),
      ),
    );
  }

  Future<bool> openMaps(String query) {
    // Universal Google Maps search URL — resolves to the native maps app when
    // installed, otherwise the browser. Works on both Android and iOS.
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1'
      '&query=${Uri.encodeComponent(query)}',
    );
    return _launch(uri, external: true);
  }

  Future<bool> _launch(Uri uri, {bool external = false}) async {
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(
      uri,
      mode: external
          ? LaunchMode.externalApplication
          : LaunchMode.platformDefault,
    );
  }

  String _encodeQuery(Map<String, String> params) {
    return params.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');
  }
}
