import 'package:ai_ui_protocol/ai_ui_protocol.dart';

/// Something the user did, in the only three shapes a transport can observe.
///
/// The engine is deliberately given *these* rather than a raw string: an
/// interaction carries the structured answer the renderer produced, and reading
/// it is what proves the loop is bidirectional rather than the agent
/// re-parsing its own prose.
sealed class AiJourneySignal {
  /// Creates a signal.
  const AiJourneySignal();
}

/// The user typed — or tapped a card action, which routes through exactly the
/// same path a typed message does.
final class AiJourneyTextSignal extends AiJourneySignal {
  /// Creates a text signal.
  const AiJourneyTextSignal(this.text);

  /// What the user sent, verbatim.
  final String text;

  /// [text] lowercased and trimmed, for keyword matching.
  String get normalized => text.trim().toLowerCase();

  /// Whether [normalized] contains every word in [words].
  bool hasAll(List<String> words) => words.every(normalized.contains);

  /// Whether [normalized] contains any of [words].
  bool hasAny(List<String> words) => words.any(normalized.contains);
}

/// The user answered a semantic card.
final class AiJourneyInteractionSignal extends AiJourneySignal {
  /// Creates an interaction signal.
  const AiJourneyInteractionSignal(this.interaction);

  /// The structured answer, straight off the renderer.
  final AiUiInteraction interaction;

  /// Shorthand for the answer's kind.
  AiUiInteractionKind get kind => interaction.kind;

  /// Whether the user answered rather than walking away.
  bool get isSubmitted => interaction.status == AiUiInteractionStatus.submitted;
}

/// The user sent real attachments on a turn.
///
/// The composer's paperclip reaches the journey through this, so a turn that
/// simply carries photos advances the media stage even when the user never
/// touched the `media_request` card.
final class AiJourneyAttachmentsSignal extends AiJourneySignal {
  /// Creates an attachments signal.
  const AiJourneyAttachmentsSignal(this.count);

  /// How many files travelled.
  final int count;
}
