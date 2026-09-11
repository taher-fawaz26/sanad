import 'dart:async';

import 'package:network/network.dart';

/// A connectivity signal a developer can flip by hand.
///
/// The offline edge case is the one state in the reference set that is **not**
/// a protocol payload: no `ui` event can produce it, because it is a fact
/// about the device rather than something the agent knows. So it has no
/// `MockScenario` — a scenario builds assistant events, and there are none to
/// build. This is its fixture instead: the dev picker's Offline chip flips
/// [isOffline], and everything after that runs the real path — `AiChatBloc`
/// queues the turn, the conversation shows the banner, and reconnecting
/// flushes the queue exactly as a radio coming back would.
///
/// Prototype-only, like `MockAiChatEventSource` beside it: the live transports
/// take the real `ConnectivityService` from the service locator.
class MockConnectivityService implements ConnectivityService {
  /// Creates a service that starts online.
  MockConnectivityService();

  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  bool _offline = false;

  /// Whether the fake radio is off.
  bool get isOffline => _offline;

  /// Flips the signal and notifies listeners.
  ///
  /// A no-op when nothing changes, matching `ConnectivityController`: a stream
  /// that re-emitted the same value would make the bloc's flush run twice.
  set isOffline(bool value) {
    if (_offline == value) return;
    _offline = value;
    if (!_controller.isClosed) _controller.add(!value);
  }

  @override
  Future<bool> isConnected() async => !_offline;

  @override
  Stream<bool> onConnectionChanged() => _controller.stream;

  /// Releases the stream. Called when the chat screen goes away.
  Future<void> dispose() => _controller.close();
}
