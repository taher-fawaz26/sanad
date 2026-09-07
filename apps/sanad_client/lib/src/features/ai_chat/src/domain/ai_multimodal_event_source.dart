import 'package:sanad_client/src/features/ai_chat/src/domain/entities/ai_outgoing_message.dart';

/// An event source that understands a turn carrying attachments.
///
/// ## Why this is a separate interface and not a member on `AiChatEventSource`
///
/// Because every source `implements` that interface rather than `extends` it,
/// and Dart requires an `implements` clause to supply **every** member —
/// including concrete ones. Adding `sendMultimodal` there with a default body
/// would therefore not be inherited: it would be a compile error in all three
/// sources, forcing edits to the SSE and WebSocket transports and their ~1300
/// lines of tests for a capability neither of them has.
///
/// Keeping it separate means a source *opts in*, and the reason above holds
/// whether or not anybody has: a member on the base interface would still have
/// to be supplied by every implementer.
///
/// All three sources have now opted in — the mock, SSE and the WebSocket — and
/// nothing above them changed to make that happen, which is the point. The
/// fallback in `AiChatBloc` remains for any future source that has no
/// multimodal contract to speak: it carries the text, and the attachments still
/// appear in the user's own bubble, so nothing is invented on a wire that
/// cannot express it.
// A one-member interface on purpose: it is a capability marker a transport
// opts into, which a top-level function cannot express.
// ignore: one_member_abstracts
abstract interface class AiMultimodalEventSource {
  /// Sends a turn that may carry attachments.
  ///
  /// Returns once the send is accepted, **not** once the reply is complete —
  /// replies arrive on the source's own `events` stream, exactly as they do
  /// for a text turn.
  Future<void> sendMultimodal(AiOutgoingMessage message);
}
