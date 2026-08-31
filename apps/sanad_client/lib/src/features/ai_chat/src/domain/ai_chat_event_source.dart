import 'package:ai_ui_protocol/ai_ui_protocol.dart';

/// Where chat events come from.
///
/// The whole transport story lives behind this one interface. The prototype
/// implements it with a scripted local source; a WebSocket implementation is a
/// new class with the same two members and changes nothing above it — no bloc
/// change, no renderer change, no protocol change. That substitutability is the
/// point of the exercise, so keep this surface small.
///
/// Implementations must never let a bad frame escape as an exception: a
/// malformed event is dropped (see `AiChatEventCodec`), not thrown.
abstract class AiChatEventSource {
  /// Broadcast, so the bloc and any diagnostics view can both listen.
  Stream<AiChatEvent> get events;

  /// Sends a user turn. Returns once the send is accepted, **not** once the
  /// reply is complete — replies arrive on [events].
  Future<void> send(String text);

  /// Releases the transport. Safe to call more than once.
  Future<void> dispose();
}
