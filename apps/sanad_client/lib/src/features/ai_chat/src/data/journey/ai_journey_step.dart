/// One scripted assistant turn.
///
/// Deliberately *not* a list of wire events: the engine decides what the agent
/// says and shows, and `MockAiChatEventSource` decides how that becomes
/// `message_start` / `text_delta` / `ui` / `message_end`. Keeping the two apart
/// is what lets the engine be a pure, synchronous, Timer-free object a unit
/// test can drive without a clock.
final class AiJourneyStep {
  /// Creates a step.
  const AiJourneyStep({
    required this.prose,
    this.ui,
    this.context,
    this.clearsContext = false,
    this.thinkingDelay = const Duration(milliseconds: 600),
  });

  /// What the agent says, streamed word by word.
  final String prose;

  /// The `ui` payload's blocks, already in wire shape. `null` for a
  /// prose-only turn.
  final List<Map<String, dynamic>>? ui;

  /// Contextual content this turn puts on offer, if any.
  ///
  /// A *second view* onto what the agent is offering rather than a second kind
  /// of reply: it rides the same turn, carries the same blocks and reuses the
  /// same node ids, so answering it and answering the card in the transcript
  /// are the same answer as far as the interaction ledger is concerned.
  final AiJourneyContext? context;

  /// Whether this turn withdraws whatever contextual content was on offer.
  ///
  /// Separate from a null [context] because "this turn has nothing to add" and
  /// "there is nothing left to offer" are different statements, and only the
  /// second should empty the surface.
  final bool clearsContext;

  /// How long the typing indicator shows before the reply starts.
  ///
  /// Per-step rather than fixed, because the pause that sells a provider search
  /// is not the pause that should precede "thanks for your feedback".
  final Duration thinkingDelay;
}

/// Contextual content in wire shape, before validation.
///
/// Raw blocks for the same reason `ai_journey_blocks.dart` is raw: the
/// contextual surface is held to exactly the policy the transcript is, so the
/// payload goes through `AiUiValidator` on its way to the screen rather than
/// around it.
final class AiJourneyContext {
  /// Creates a contextual payload.
  const AiJourneyContext({
    required this.id,
    required this.peekLabel,
    required this.blocks,
  });

  /// Identifies this payload; a different id is what tells the surface its
  /// body changed.
  final String id;

  /// The summary on the affordance — "You have 8 new offers".
  final String peekLabel;

  /// The blocks the surface renders, in wire shape.
  final List<Map<String, dynamic>> blocks;
}
