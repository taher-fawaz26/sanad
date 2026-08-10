import 'package:meta/meta.dart';

/// Declares which incoming URIs an app treats as deep links.
///
/// A URI is accepted when its scheme is one of [schemes] (custom schemes are
/// inherently app-specific, so no host check applies) or when its scheme is
/// `http`/`https` and its host is one of [hosts] (Android App Links / iOS
/// Universal Links).
@immutable
class DeepLinkConfig {
  /// Creates a [DeepLinkConfig] from the trusted [schemes] and [hosts].
  const DeepLinkConfig({this.schemes = const {}, this.hosts = const {}});

  /// Custom URL schemes this app registers, e.g. `{'sanadprovider'}`.
  final Set<String> schemes;

  /// Verified web hosts this app handles, e.g. `{'links.trysanad.us'}`.
  final Set<String> hosts;

  /// Whether [uri] originates from a source this config trusts.
  bool accepts(Uri uri) {
    if (schemes.contains(uri.scheme)) return true;
    if ((uri.scheme == 'http' || uri.scheme == 'https') &&
        hosts.contains(uri.host)) {
      return true;
    }
    return false;
  }
}
