import 'dart:async';

import 'package:deep_linking/src/deep_linking_service.dart';

/// Wires a [DeepLinkingService] to the app's navigation, independent of
/// which router implementation is used.
///
/// Feeds its navigation callback with the cold-start link and every
/// subsequent link (warm start / resume) as a router-ready location
/// string, e.g. `/invitation/abc123`. Pass `GoRouter.go` (or an
/// equivalent) as that callback — this class has no GoRouter dependency,
/// so it stays testable with a plain function.
class DeepLinkDispatcher {
  /// Creates a [DeepLinkDispatcher] over [service], calling [onNavigate]
  /// for every validated link.
  DeepLinkDispatcher({
    required DeepLinkingService service,
    required void Function(String location) onNavigate,
  }) : _service = service,
       _onNavigate = onNavigate;

  final DeepLinkingService _service;
  final void Function(String location) _onNavigate;
  StreamSubscription<void>? _subscription;

  /// Dispatches the cold-start link (if any), then subscribes to further
  /// links for the remainder of the app's lifetime.
  Future<void> start() async {
    final initial = await _service.getInitialLink();
    if (initial != null) _onNavigate(initial.location);
    _subscription = _service.onLink.listen(
      (link) => _onNavigate(link.location),
    );
  }

  /// Cancels the subscription. Does not dispose the underlying service.
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
