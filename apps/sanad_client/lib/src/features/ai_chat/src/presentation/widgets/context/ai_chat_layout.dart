import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Which slot of [AiChatLayout] a child occupies.
enum _AiChatSlot { conversation, context, composer }

/// The chat page's three-layer skeleton: conversation, then the context layer,
/// then the composer **on top of the context layer**.
///
/// ## Why this exists rather than a `Stack` or a `Column`
///
/// The hard constraint is z-order. The context layer slides up from *behind*
/// the composer and the composer stays above it, and never moves, at every
/// extent. A `Column` gets the composer's height right but paints its children
/// in document order, so nothing can be drawn between the conversation and the
/// composer. A `Stack` gets the paint order right but knows nothing about how
/// tall the composer is, so the conversation ends up underneath it.
///
/// [CustomMultiChildLayout] gives both in a single layout pass: the composer is
/// laid out first and reports its own height, the conversation is then given
/// exactly the space above it, and the children paint in the order they are
/// listed. No `GlobalKey`, no post-frame measurement, no frame where the
/// conversation is mis-sized.
///
/// ## The bleed
///
/// The context slot is deliberately [bleed] logical pixels *taller* than the
/// conversation area, so its lower edge finishes behind the composer rather
/// than stopping at its top edge. That is what lets its rounded top corners
/// emerge from under a translucent composer instead of reading as a panel that
/// happens to end exactly where the composer begins.
///
/// The context child is therefore handed `conversationHeight + bleed` and is
/// expected to anchor its own panel to the bottom of that box.
///
/// Chat-local by design — see `AiChatContextController` for why this is not in
/// `packages/sheet_navigation`.
class AiChatLayout extends StatelessWidget {
  /// Creates the layered page skeleton.
  const AiChatLayout({
    required this.conversation,
    required this.composer,
    super.key,
    this.context,
    this.bleed = defaultBleed,
  });

  /// How far the context layer's box extends behind [composer], in logical
  /// pixels.
  ///
  /// Enough for a large corner radius plus a shadow to disappear behind the
  /// composer; small enough that a short composer still covers it.
  static const double defaultBleed = 44;

  /// The transcript and everything above it — laid out in the space above
  /// [composer]. Painted first, so the context layer covers it as it rises.
  final Widget conversation;

  /// The sliding surface, or null when there is nothing to offer.
  ///
  /// Null rather than an invisible widget: a layer with no content should not
  /// be in the tree at all, and passing null is how the page says so.
  final Widget? context;

  /// Pinned to the bottom at its own intrinsic height, and painted last so it
  /// is above the context layer at every extent.
  final Widget composer;

  /// See [defaultBleed].
  final double bleed;

  @override
  Widget build(BuildContext buildContext) {
    final layer = context;

    return CustomMultiChildLayout(
      delegate: _AiChatLayoutDelegate(bleed: bleed, hasContext: layer != null),
      children: [
        // Order is paint order. Do not reorder.
        LayoutId(id: _AiChatSlot.conversation, child: conversation),
        if (layer != null) LayoutId(id: _AiChatSlot.context, child: layer),
        LayoutId(id: _AiChatSlot.composer, child: composer),
      ],
    );
  }
}

class _AiChatLayoutDelegate extends MultiChildLayoutDelegate {
  _AiChatLayoutDelegate({required this.bleed, required this.hasContext});

  final double bleed;
  final bool hasContext;

  @override
  void performLayout(Size size) {
    // The composer first: everything else is expressed relative to how tall it
    // turned out to be, and it is the only child whose height is its own.
    final composerSize = layoutChild(
      _AiChatSlot.composer,
      BoxConstraints.loose(size),
    );
    positionChild(
      _AiChatSlot.composer,
      Offset(0, size.height - composerSize.height),
    );

    final conversationHeight = math.max<double>(
      0,
      size.height - composerSize.height,
    );
    layoutChild(
      _AiChatSlot.conversation,
      BoxConstraints.tight(Size(size.width, conversationHeight)),
    );
    positionChild(_AiChatSlot.conversation, Offset.zero);

    if (!hasContext) return;

    // Taller than the conversation area by the bleed, so the layer's bottom
    // edge finishes behind the composer. See the class doc.
    layoutChild(
      _AiChatSlot.context,
      BoxConstraints.tight(Size(size.width, conversationHeight + bleed)),
    );
    positionChild(_AiChatSlot.context, Offset.zero);
  }

  @override
  bool shouldRelayout(_AiChatLayoutDelegate oldDelegate) =>
      oldDelegate.bleed != bleed || oldDelegate.hasContext != hasContext;
}
