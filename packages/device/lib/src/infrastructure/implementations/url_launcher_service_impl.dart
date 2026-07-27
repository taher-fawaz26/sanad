import 'package:device/src/domain/services/url_launcher_service.dart';
import 'package:device/src/infrastructure/providers/url_launcher_provider.dart';

class UrlLauncherServiceImpl implements UrlLauncherService {
  const UrlLauncherServiceImpl(this._provider);

  final UrlLauncherProvider _provider;

  @override
  Future<bool> openUrl(String url) => _provider.openUrl(url);

  @override
  Future<bool> openPhone(String phoneNumber) =>
      _provider.openPhone(phoneNumber);

  @override
  Future<bool> openEmail(String email, {String? subject, String? body}) =>
      _provider.openEmail(email, subject: subject, body: body);

  @override
  Future<bool> openSms(String phoneNumber, {String? body}) =>
      _provider.openSms(phoneNumber, body: body);

  @override
  Future<bool> openMaps(String query) => _provider.openMaps(query);
}
