/// Generic application-wide deep-link infrastructure.
///
/// Turns OS-level incoming URIs (Android App Links, iOS Universal Links, or
/// a custom URL scheme) into GoRouter-navigable locations, with no
/// knowledge of individual features. See `DeepLinkDispatcher`.
library;

export 'src/deep_link.dart';
export 'src/deep_link_config.dart';
export 'src/deep_link_dispatcher.dart';
export 'src/deep_link_parser.dart';
export 'src/deep_linking_di.dart';
export 'src/deep_linking_service.dart';
export 'src/deep_linking_service_impl.dart';
