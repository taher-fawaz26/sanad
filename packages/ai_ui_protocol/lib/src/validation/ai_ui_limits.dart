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
    this.maxImages = 4,
    this.maxLines = 20,
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
  final int maxImages;
  final int maxLines;

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
  ];
}
