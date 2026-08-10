import 'package:deep_linking/src/deep_link.dart';

/// Contract for observing OS-level incoming deep links.
///
/// Implementations must never throw on malformed input — invalid or
/// untrusted links resolve to `null` (initial link) or are simply not
/// emitted (stream) — and must not re-emit the same link twice.
abstract interface class DeepLinkingService {
  /// The link that launched the app (cold start), if any.
  ///
  /// Resolves once per process lifetime; call it before subscribing to
  /// [onLink] so no link is missed or double-handled.
  Future<DeepLink?> getInitialLink();

  /// Emits every subsequent deep link received while the app is running
  /// (warm start / resume), already validated and de-duplicated.
  Stream<DeepLink> get onLink;

  /// Releases the underlying OS link subscription.
  void dispose();
}
