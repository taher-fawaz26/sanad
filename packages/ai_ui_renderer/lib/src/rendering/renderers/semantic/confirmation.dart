import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/src/interaction/ai_interaction_gate.dart';
import 'package:ai_ui_renderer/src/rendering/ai_node_renderer.dart';
import 'package:ai_ui_renderer/src/rendering/ai_ui_render_scope.dart';
import 'package:ai_ui_renderer/src/rendering/primitives/ai_card_surface.dart';
import 'package:ai_ui_renderer/src/rendering/primitives/ai_prompt_parts.dart';
import 'package:ai_ui_renderer/src/rendering/primitives/ai_status_parts.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// The shared yes-or-no, and the card that is nothing but one.
///
/// Every card ending in "confirm or cancel" draws [AiConfirmChoiceRow] and
/// answers through the same `confirmation_resolved` interaction. One widget
/// rather than a pair of buttons per renderer is what keeps three properties
/// true everywhere at once: the answer is structured, the ledger stops a
/// second tap, and declining is *sent* rather than swallowed.

/// The two controls a [AiUiConfirmChoice] describes.
///
/// Order follows which choice is dangerous. Normally the affirmative sits at
/// the trailing edge, where a reader's thumb finishes — but when confirming is
/// the destructive act ("Yes, cancel my booking") it leads, so the safe option
/// is the one in the position muscle memory reaches for. Both readings mirror
/// under RTL because the row is a `Row`, not a left-and-right pair.
class AiConfirmChoiceRow extends StatelessWidget {
  /// Creates the row.
  const AiConfirmChoiceRow({
    required this.choice,
    required this.nodeId,
    required this.nodeType,
    required this.scope,
    this.stacked = false,
    super.key,
  });

  final AiUiConfirmChoice choice;

  /// The node this answer belongs to — what the result is correlated by and
  /// what the ledger claims.
  final String nodeId;
  final AiUiNodeType nodeType;
  final AiUiRenderScope scope;

  /// Draws the pair as two full-width pills, affirmative on top.
  ///
  /// The reading the notice cards and the exhausted `provider_search` use, and
  /// the *card's* decision rather than the payload's — same reasoning as
  /// [AiCardActionRow.stacked]. Order does not flip for a destructive confirm
  /// here: stacked, the affirmative is already the one furthest from the
  /// thumb's resting position, so leading with it does not put the dangerous
  /// control where muscle memory reaches.
  final bool stacked;

  @override
  Widget build(BuildContext context) => AiInteractionGate(
    nodeId: nodeId,
    ledger: scope.ledger,
    builder: (context, state) {
      // One answer per card. After it has gone the controls stay visible as a
      // record of what was asked, but neither can be taken again.
      final onConfirm = state.isInteractive
          ? () => _submit(context, confirmed: true)
          : null;
      final onCancel = state.isInteractive
          ? () => _submit(context, confirmed: false)
          : null;

      if (stacked) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.sm,
          children: [
            AiPromptButton(
              label: choice.confirmLabel,
              intent: choice.destructive
                  ? AiUiButtonIntent.destructive
                  : AiUiButtonIntent.standard,
              compact: true,
              onTap: onConfirm,
            ),
            if (choice.cancelLabel != null)
              AiPromptButton(
                label: choice.cancelLabel!,
                filled: false,
                compact: true,
                onTap: onCancel,
              ),
          ],
        );
      }

      final confirm = AiCardButton(
        label: choice.confirmLabel,
        intent: choice.destructive
            ? AiUiButtonIntent.destructive
            : AiUiButtonIntent.standard,
        onTap: onConfirm,
      );

      if (choice.cancelLabel == null) return confirm;

      final cancel = AiCardButton(
        label: choice.cancelLabel!,
        // Outline for the safe option beside a destructive confirm, tonal
        // otherwise — the two readings Figma draws for this pair.
        variant: choice.destructive
            ? AiUiButtonVariant.outline
            : AiUiButtonVariant.secondary,
        intent: choice.destructive
            ? AiUiButtonIntent.standard
            : AiUiButtonIntent.neutral,
        onTap: onCancel,
      );

      return Row(
        spacing: AppSpacing.md,
        children: choice.destructive
            ? [Expanded(child: confirm), Expanded(child: cancel)]
            : [Expanded(child: cancel), Expanded(child: confirm)],
      );
    },
  );

  void _submit(BuildContext context, {required bool confirmed}) {
    final template = confirmed ? choice.confirmTemplate : choice.cancelTemplate;

    scope.submitInteraction(
      context,
      nodeId: nodeId,
      nodeType: nodeType,
      kind: AiUiInteractionKind.confirmationResolved,
      // Declining is `submitted`, not `cancelled`: the user answered the
      // question and the answer was no. A `cancelled` status means they walked
      // away without answering, and an agent that conflated the two would
      // re-ask something the user already refused.
      value: AiUiConfirmationValue(
        confirmed: confirmed,
        reference: choice.reference,
      ),
      // No template means the interaction travels without prose and the host
      // supplies its own words, exactly as a permission outcome does — the
      // agent never authored "no thanks", and this package holds no
      // translations.
      text: template,
    );
  }
}

/// `confirm_prompt` — Figma `cancel-confirmation-card`.
class AiUiConfirmPromptRenderer extends AiNodeRenderer<AiUiConfirmPromptNode> {
  /// Creates the renderer.
  const AiUiConfirmPromptRenderer();

  @override
  Widget render(
    BuildContext context,
    AiUiConfirmPromptNode node,
    AiUiRenderScope scope,
  ) => AiSemanticCard(
    semanticsLabel: node.a11yLabel ?? node.title,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.lg,
      children: [
        AiPromptHeader(title: node.title, body: node.body, compact: true),
        if (node.subjectTitle != null)
          AiSubjectTile(
            title: node.subjectTitle!,
            subtitle: node.subjectSubtitle,
          ),
        AiConfirmChoiceRow(
          choice: node.confirm,
          nodeId: node.id,
          nodeType: AiUiNodeType.confirmPrompt,
          scope: scope,
        ),
      ],
    ),
  );
}
