import 'package:ai_ui_protocol/ai_ui_protocol.dart';

/// Where a semantic node's answer goes.
///
/// The mirror of `AiActionRegistry`: that seam carries the agent's *requests*
/// into the app, this one carries the user's *results* back out. Keeping them
/// as two seams is what makes the direction of any given call obvious at the
/// call site, and it is why a result can never be dispatched as an action.
///
/// One implementation per transport, and only the transport differs:
/// `sanad_client`'s chat sink turns the interaction into a turn on the
/// existing SSE/WebSocket request, and its voice sink hands the same object to
/// the live session. Neither owns the protocol, the lifecycle, or the
/// rendering.
///
/// Implementations must not throw — a submission that cannot be sent is
/// reported through the ledger as
/// `AiUiNodeInteractionState.failed`, never as an exception crossing back into
/// a widget's tap handler.
// A one-member interface on purpose: it is a capability a transport
// implements, and it has to be substitutable — the no-op below is what keeps
// every host that has no agent to answer working unchanged. A top-level
// function can express neither.
// ignore: one_member_abstracts
abstract interface class AiUiInteractionSink {
  /// Sends [interaction] to the agent.
  ///
  /// Called after the ledger has already accepted the submission, so an
  /// implementation does not repeat the duplicate check.
  void submit(AiUiInteraction interaction);
}

/// A sink that sends nothing.
///
/// The default in `AiUiEnvironment`, which is what keeps every existing host
/// compiling and behaving unchanged: the design catalog, the showcase page and
/// the renderer's own tests have no agent to answer. `AiUiRenderScope`
/// recognises this type and falls back to dispatching the interaction's prose
/// as a `send_message` action, which is exactly what the interactive cards did
/// before results existed.
final class NoopAiUiInteractionSink implements AiUiInteractionSink {
  /// Creates the no-op sink.
  const NoopAiUiInteractionSink();

  @override
  void submit(AiUiInteraction interaction) {}
}

/// Action params the *client* adds when a capability request originates from a
/// semantic node.
///
/// The agent authors an action's meaning; these carry the correlation the app
/// needs to turn an asynchronous outcome — a permission dialog, a picker —
/// back into a result the agent can match to the node it asked from. Without
/// them a `request_permission` handler would know the capability but not the
/// question.
abstract final class AiUiInteractionParams {
  AiUiInteractionParams._();

  /// The id of the node whose control was tapped.
  static const String nodeId = 'nodeId';

  /// The id of the assistant message that carried the node.
  static const String messageId = 'messageId';
}
