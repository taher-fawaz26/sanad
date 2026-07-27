/// Launches external targets (URLs, dialer, mail, SMS, maps).
abstract class UrlLauncherService {
  /// Opens an arbitrary [url] in the platform default handler/browser.
  Future<bool> openUrl(String url);

  /// Opens the phone dialer pre-filled with [phoneNumber].
  Future<bool> openPhone(String phoneNumber);

  /// Opens the mail composer to [email], with optional [subject] / [body].
  Future<bool> openEmail(String email, {String? subject, String? body});

  /// Opens the SMS composer to [phoneNumber], with an optional [body].
  Future<bool> openSms(String phoneNumber, {String? body});

  /// Opens the platform maps app at [query] (address or "lat,lng").
  Future<bool> openMaps(String query);
}
