import 'package:deep_linking/src/deep_link.dart';
import 'package:deep_linking/src/deep_link_config.dart';

/// Parses and validates incoming URIs into navigable [DeepLink]s.
///
/// Deliberately dumb: it only turns a trusted URI into a router location
/// string. It knows nothing about invitations, backend verification, or any
/// other feature — that stays entirely inside GoRouter and whichever feature
/// package owns the route matching [DeepLink.location].
abstract final class DeepLinkParser {
  const DeepLinkParser._();

  /// Returns a [DeepLink] for [uri], or `null` if [uri] is not a link this
  /// app should handle (wrong scheme/host, or an empty path).
  static DeepLink? parse(Uri uri, DeepLinkConfig config) {
    if (!config.accepts(uri)) return null;
    if (uri.path.isEmpty || uri.path == '/') return null;

    final location = uri.query.isEmpty ? uri.path : '${uri.path}?${uri.query}';
    return DeepLink(uri: uri, location: location);
  }
}
