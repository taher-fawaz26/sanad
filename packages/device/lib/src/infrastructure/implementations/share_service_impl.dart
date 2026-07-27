import 'package:device/src/domain/entities/share_result.dart';
import 'package:device/src/domain/services/share_service.dart';
import 'package:device/src/infrastructure/providers/share_provider.dart';

class ShareServiceImpl implements ShareService {
  const ShareServiceImpl(this._provider);

  final ShareProvider _provider;

  @override
  Future<ShareResult> shareText(String text, {String? subject}) =>
      _provider.shareText(text, subject: subject);

  @override
  Future<ShareResult> shareFiles(List<String> paths, {String? text}) =>
      _provider.shareFiles(paths, text: text);

  @override
  Future<ShareResult> shareUri(String uri) => _provider.shareUri(uri);
}
