import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:deep_linking/src/deep_link.dart';
import 'package:deep_linking/src/deep_link_config.dart';
import 'package:deep_linking/src/deep_link_parser.dart';
import 'package:deep_linking/src/deep_linking_service.dart';

/// [DeepLinkingService] backed by the `app_links` plugin.
///
/// Treats every incoming URI as untrusted: [DeepLinkParser] is the only
/// gate, and this class never calls into feature or backend code — it only
/// ever hands a validated [DeepLink] to whoever listens to [onLink].
class DeepLinkingServiceImpl implements DeepLinkingService {
  /// Creates a [DeepLinkingServiceImpl] validating links against [config].
  ///
  /// [appLinks] is injectable for testing; defaults to a real [AppLinks].
  DeepLinkingServiceImpl({required DeepLinkConfig config, AppLinks? appLinks})
    : _config = config,
      _appLinks = appLinks ?? AppLinks();

  final DeepLinkConfig _config;
  final AppLinks _appLinks;

  Uri? _lastHandledUri;
  StreamController<DeepLink>? _controller;
  StreamSubscription<Uri>? _osSubscription;

  @override
  Future<DeepLink?> getInitialLink() async {
    Uri? uri;
    try {
      uri = await _appLinks.getInitialLink();
    } on Object {
      return null;
    }
    if (uri == null) return null;
    return _handle(uri);
  }

  @override
  Stream<DeepLink> get onLink => (_controller ??= _createController()).stream;

  StreamController<DeepLink> _createController() {
    final controller = StreamController<DeepLink>.broadcast();
    _osSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        final link = _handle(uri);
        if (link != null) controller.add(link);
      },
      onError: (Object _) {},
    );
    return controller;
  }

  DeepLink? _handle(Uri uri) {
    if (uri == _lastHandledUri) return null;
    final link = DeepLinkParser.parse(uri, _config);
    if (link == null) return null;
    _lastHandledUri = uri;
    return link;
  }

  @override
  void dispose() {
    _osSubscription?.cancel();
    _osSubscription = null;
    _controller?.close();
    _controller = null;
  }
}
