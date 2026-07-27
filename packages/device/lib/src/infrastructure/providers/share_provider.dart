import 'package:device/src/domain/entities/share_result.dart';
import 'package:device/src/domain/enums/share_status.dart';
import 'package:share_plus/share_plus.dart' as sp;

/// Wraps `share_plus`. No plugin type escapes this class.
class ShareProvider {
  const ShareProvider();

  Future<ShareResult> shareText(String text, {String? subject}) {
    return _share(sp.ShareParams(text: text, subject: subject));
  }

  Future<ShareResult> shareFiles(List<String> paths, {String? text}) {
    return _share(
      sp.ShareParams(
        files: paths.map(sp.XFile.new).toList(),
        text: text,
      ),
    );
  }

  Future<ShareResult> shareUri(String uri) {
    return _share(sp.ShareParams(uri: Uri.parse(uri)));
  }

  Future<ShareResult> _share(sp.ShareParams params) async {
    final result = await sp.SharePlus.instance.share(params);
    return ShareResult(status: _mapStatus(result.status), raw: result.raw);
  }

  ShareStatus _mapStatus(sp.ShareResultStatus status) {
    return switch (status) {
      sp.ShareResultStatus.success => ShareStatus.success,
      sp.ShareResultStatus.dismissed => ShareStatus.dismissed,
      sp.ShareResultStatus.unavailable => ShareStatus.unavailable,
    };
  }
}
