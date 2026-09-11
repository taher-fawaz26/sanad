import 'package:ai_ui_protocol/src/domain/ai_ui_node_type.dart';
import 'package:equatable/equatable.dart';

/// Hard bounds on what an AI payload may ask the client to build.
///
/// These exist so a pathological (or adversarial) tree cannot cost unbounded
/// layout work or memory. They are enforced *before* any widget is
/// constructed, so exceeding one is cheap.
///
/// Two different failure modes on purpose:
///   * a **child / depth** overrun truncates the offending container and keeps
///     going — one greedy list should not blank the whole reply;
///   * a **payload size / node count** overrun rejects the entire document —
///     past that point the payload is not something we want to walk at all.
final class AiUiLimits extends Equatable {
  const AiUiLimits({
    this.maxPayloadBytes = 32 * 1024,
    this.maxNodes = 100,
    this.maxDepth = 6,
    this.maxBlocks = 12,
    this.maxRowChildren = 8,
    this.maxColumnChildren = 12,
    this.maxCardChildren = 12,
    this.maxListChildren = 20,
    this.maxRichTextSpans = 20,
    this.maxQuickReplyOptions = 6,
    this.minQuickReplyOptions = 2,
    this.maxTextLength = 2000,
    this.maxLabelLength = 64,
    this.maxChipLabelLength = 40,
    this.maxActions = 12,
    this.maxImages = 8,
    this.maxLines = 20,
    this.maxCardActions = 3,
    this.maxDetailItems = 8,
    this.maxTimeSlots = 12,
    this.minTimeSlots = 2,
    this.maxSavedLocations = 6,
    this.maxMediaOptions = 4,
    this.maxStats = 4,
    this.maxCommentLength = 500,
    this.maxInteractionTextLength = 2000,
    this.maxTimelineItems = 8,
    this.maxPhotos = 6,
    this.maxServiceTags = 8,
    this.maxRating = 10,
    this.maxVerificationCodeLength = 12,
  });

  static const AiUiLimits defaults = AiUiLimits();

  final int maxPayloadBytes;
  final int maxNodes;

  /// `blocks` themselves are depth 1.
  final int maxDepth;
  final int maxBlocks;
  final int maxRowChildren;
  final int maxColumnChildren;
  final int maxCardChildren;
  final int maxListChildren;
  final int maxRichTextSpans;
  final int maxQuickReplyOptions;
  final int minQuickReplyOptions;
  final int maxTextLength;
  final int maxLabelLength;
  final int maxChipLabelLength;
  final int maxActions;

  /// Images per message. Raised from 4 when `image.url` was admitted: with
  /// dynamic media the common case, four is one order list plus an avatar, and
  /// the fifth picture would vanish silently. Still bounded — it caps how many
  /// network fetches one bubble can start.
  final int maxImages;
  final int maxLines;

  /// Buttons in a semantic card's attached `actions` row. Three is what the
  /// widest Figma card uses; a fourth would wrap and stop reading as a row.
  final int maxCardActions;

  /// Label-and-value rows in a summary, receipt or details card.
  final int maxDetailItems;

  /// Selectable slots in a `time_slots` node. Twelve fills six rows of two,
  /// which is already the tallest card in the set.
  final int maxTimeSlots;

  /// Below this a slot grid is not a choice — one option should be a
  /// `quick_reply`, not a selector with a confirm button.
  final int minTimeSlots;

  final int maxSavedLocations;
  final int maxMediaOptions;
  final int maxStats;

  /// Characters the user may type into a `review_request` comment field. The
  /// agent may lower it per node; it can never raise it.
  final int maxCommentLength;

  /// Caps every free-text field on an outgoing interaction result.
  ///
  /// A backstop, not the primary guard: `review_request` already clamps the
  /// comment box and the agent's own labels are bounded. What is *not*
  /// bounded upstream is what a user types into a `location_picker`'s search
  /// field, which is why the encoder applies this to every path.
  final int maxInteractionTextLength;

  /// Steps in a `service_timeline`. Eight covers the longest lifecycle the
  /// product has; a ninth turns the card into a scroll region inside a bubble.
  final int maxTimelineItems;

  /// Pictures in a `provider_card`'s work strip or a `request_summary`'s
  /// attachment row. Each still counts against [maxImages], which is the
  /// harder cap — this one only stops one node eating the whole budget.
  final int maxPhotos;

  /// Service chips on a `provider_card`.
  final int maxServiceTags;

  /// Ceiling on `review_request.maxRating`. The agent may ask for a smaller
  /// scale, never a larger one — a forty-star row would not fit and would not
  /// mean anything.
  final int maxRating;

  /// Characters in a `verification_code`. Each one draws its own box, so this
  /// is what keeps the row from overflowing the card rather than a byte limit.
  final int maxVerificationCodeLength;

  /// Child cap for a given container type.
  int childLimitFor(AiUiNodeType type) => switch (type) {
    AiUiNodeType.row => maxRowChildren,
    AiUiNodeType.column => maxColumnChildren,
    AiUiNodeType.card => maxCardChildren,
    AiUiNodeType.list => maxListChildren,
    _ => 0,
  };

  @override
  List<Object?> get props => [
    maxPayloadBytes,
    maxNodes,
    maxDepth,
    maxBlocks,
    maxRowChildren,
    maxColumnChildren,
    maxCardChildren,
    maxListChildren,
    maxRichTextSpans,
    maxQuickReplyOptions,
    minQuickReplyOptions,
    maxTextLength,
    maxLabelLength,
    maxChipLabelLength,
    maxActions,
    maxImages,
    maxLines,
    maxCardActions,
    maxDetailItems,
    maxTimeSlots,
    minTimeSlots,
    maxSavedLocations,
    maxMediaOptions,
    maxStats,
    maxCommentLength,
    maxInteractionTextLength,
    maxTimelineItems,
    maxPhotos,
    maxServiceTags,
    maxRating,
    maxVerificationCodeLength,
  ];
}
