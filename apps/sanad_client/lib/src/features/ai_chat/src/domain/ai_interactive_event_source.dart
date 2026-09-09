import 'package:ai_ui_protocol/ai_ui_protocol.dart';

/// An event source that understands a turn carrying a structured answer.
///
/// ## Why this is a separate interface and not a member on `AiChatEventSource`
///
/// The same reason `AiMultimodalEventSource` is separate: every source
/// `implements` the base interface rather than extending it, so a member added
/// there — even a concrete one — must be supplied by every implementer. A
/// capability marker a transport *opts into* keeps that cost where it belongs.
///
/// ## Why the prose travels with the result
///
/// `text` is the sentence the agent's own template produced. It goes in the
/// turn's `message` exactly as it always did, so a backend that has not
/// implemented `interaction` is unaffected: it receives the same body a tapped
/// card has always sent. The structured half is additive, and a source that
/// cannot express it degrades to `send(text)` — which is literally the
/// behaviour that shipped before results existed.
// A one-member interface on purpose: it is a capability marker a transport
// opts into, which a top-level function cannot express.
// ignore: one_member_abstracts
abstract interface class AiInteractiveEventSource {
  /// Sends one structured answer.
  ///
  /// Returns once the send is accepted, **not** once the reply is complete —
  /// the continuation arrives on the source's own `events` stream, exactly as
  /// it does for a typed turn.
  Future<void> sendInteraction(
    AiUiInteraction interaction, {
    required String text,
  });
}
