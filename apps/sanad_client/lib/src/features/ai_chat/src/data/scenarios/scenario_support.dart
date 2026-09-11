/// The `MockScenario` type and the wire-shaped event builders every fixture
/// is assembled from.
///
/// Extracted from `mock_scenarios.dart` when the fixture set grew to one
/// scenario per semantic component: the builders are shared by both halves of
/// the catalog, and a data file of that size is easier to read split by
/// subject than kept in one list.
library;

import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:core/core.dart';

/// A scripted assistant turn.
///
/// Scenarios build *wire-shaped* events — the same envelope a WebSocket would
/// deliver — so replacing this source with a real one changes nothing above it.
/// Several are deliberately broken: proving the chat survives a hostile payload
/// matters more than proving it renders a nice card.
final class MockScenario {
  /// Creates a scenario.
  const MockScenario({
    required this.id,
    required this.label,
    required this.build,
    this.keywords = const [],
  });

  /// Stable identifier, used by the dev scenario picker.
  final String id;

  /// Human-readable name shown in the picker.
  final String label;

  /// Keywords that select this scenario from the user's message, so the
  /// prototype feels conversational rather than menu-driven.
  final List<String> keywords;

  /// Produces the scripted events for one assistant turn.
  final List<AiChatEvent> Function(String messageId) build;
}

/// Wraps [blocks] in a well-formed `ui` payload.
Map<String, dynamic> scenarioPayload(List<Map<String, dynamic>> blocks) =>
    <String, dynamic>{'schemaVersion': 1, 'blocks': blocks};

/// Opens an assistant message.
AiChatEvent scenarioStart(String messageId) => AiChatMessageStartEvent(
  eventId: 'evt_${generateUuidV4()}',
  messageId: messageId,
);

/// One streamed increment.
AiChatEvent scenarioDelta(String messageId, String delta) =>
    AiChatTextDeltaEvent(
      eventId: 'evt_${generateUuidV4()}',
      messageId: messageId,
      delta: delta,
    );

/// Closes a message with its authoritative text.
AiChatEvent scenarioEnd(String messageId, String text) => AiChatMessageEndEvent(
  eventId: 'evt_${generateUuidV4()}',
  messageId: messageId,
  text: text,
);

/// Attaches a structured-UI payload to a message.
AiChatEvent scenarioUi(String messageId, Map<String, dynamic> payload) =>
    AiChatUiEvent(
      eventId: 'evt_${generateUuidV4()}',
      messageId: messageId,
      payload: payload,
    );

/// An agent-side failure.
///
/// The only way a scripted source can drive the *message lifecycle* rather
/// than the message list: the bloc marks whatever turn was in flight as
/// `failed` when this lands, which is exactly what a dropped send does on a
/// live transport. Nothing about the failed bubble is faked.
AiChatEvent scenarioError(String code, {String? message}) => AiChatErrorEvent(
  eventId: 'evt_${generateUuidV4()}',
  code: code,
  message: message,
);

/// Splits [text] into word-sized deltas so streaming looks like streaming.
List<AiChatEvent> scenarioStream(String messageId, String text) {
  final words = text.split(' ');
  return [
    for (var i = 0; i < words.length; i++)
      scenarioDelta(messageId, i == 0 ? words[i] : ' ${words[i]}'),
  ];
}

/// A whole prose-only turn: start, deltas, end.
List<AiChatEvent> scenarioSay(String messageId, String text) => [
  scenarioStart(messageId),
  ...scenarioStream(messageId, text),
  scenarioEnd(messageId, text),
];
