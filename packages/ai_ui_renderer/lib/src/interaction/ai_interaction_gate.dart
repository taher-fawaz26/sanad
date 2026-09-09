import 'package:ai_ui_renderer/src/interaction/ai_ui_interaction_ledger.dart';
import 'package:flutter/widgets.dart';

/// Rebuilds [builder] when one node's answer lifecycle changes.
///
/// The reason the ledger hands out a listenable per node rather than exposing
/// one notifier: a conversation is a `ListView` of bubbles, and selecting a
/// time slot must rebuild the confirm button and nothing else. Wrapping only
/// the controls — not the whole card — keeps that true even inside a card that
/// is expensive to lay out.
class AiInteractionGate extends StatelessWidget {
  /// Creates a gate around [nodeId]'s controls.
  const AiInteractionGate({
    required this.nodeId,
    required this.ledger,
    required this.builder,
    super.key,
  });

  /// The node whose lifecycle drives this subtree.
  final String nodeId;

  /// The ledger to read. Comes from the render scope.
  final AiUiInteractionLedger ledger;

  /// Builds the controls for the current state.
  final Widget Function(BuildContext context, AiUiNodeInteractionState state)
  builder;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<AiUiNodeInteractionState>(
        valueListenable: ledger.watch(nodeId),
        builder: (context, state, _) => builder(context, state),
      );
}
