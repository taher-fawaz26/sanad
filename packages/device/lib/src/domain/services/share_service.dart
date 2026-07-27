import 'package:device/src/domain/entities/share_result.dart';

/// Shares content to other apps via the system share sheet.
abstract class ShareService {
  /// Shares plain [text], with an optional [subject] (used by e.g. email).
  Future<ShareResult> shareText(String text, {String? subject});

  /// Shares one or more files identified by absolute filesystem [paths].
  Future<ShareResult> shareFiles(List<String> paths, {String? text});

  /// Shares a [uri] (link).
  Future<ShareResult> shareUri(String uri);
}
