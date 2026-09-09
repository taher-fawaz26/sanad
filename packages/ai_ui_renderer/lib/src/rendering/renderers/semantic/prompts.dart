import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/src/interaction/ai_interaction_gate.dart';
import 'package:ai_ui_renderer/src/interaction/ai_ui_interaction_ledger.dart';
import 'package:ai_ui_renderer/src/rendering/ai_card_tokens.dart';
import 'package:ai_ui_renderer/src/rendering/ai_node_renderer.dart';
import 'package:ai_ui_renderer/src/rendering/ai_ui_render_scope.dart';
import 'package:ai_ui_renderer/src/rendering/ai_ui_tokens.dart';
import 'package:ai_ui_renderer/src/rendering/primitives/ai_card_content.dart';
import 'package:ai_ui_renderer/src/rendering/primitives/ai_card_surface.dart';
import 'package:ai_ui_renderer/src/rendering/primitives/ai_prompt_parts.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// The cards that ask for a decision or a capability.
///
/// Figma draws four of these as bottom sheets. Rendered here as blocks inside
/// the assistant bubble, they keep every part of the sheet's content — the
/// 24dp headline, the option rows, the map preview, the full-width CTA — and
/// lose only the sheet's own grabber and home indicator, which a chat bubble
/// has no equivalent for.

/// `reminder_card` — Figma `alert-card` (`8015:29574`).
class AiUiReminderCardRenderer extends AiNodeRenderer<AiUiReminderCardNode> {
  /// Creates the renderer.
  const AiUiReminderCardRenderer();

  @override
  Widget render(
    BuildContext context,
    AiUiReminderCardNode node,
    AiUiRenderScope scope,
  ) => AiSemanticCard(
    semanticsLabel: node.a11yLabel ?? '${node.title}. ${node.body}',
    // The tinted edge is what makes a reminder read as time-sensitive without
    // filling the card and fighting its text for contrast.
    borderTone: node.tone,
    emphasised: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.lg,
      children: [
        AiCardHeader(
          leading: AiToneDisc(
            tone: node.tone,
            icon: _glyphFor(node.tone),
          ),
          title: node.title,
          subtitle: node.subtitle,
        ),
        AiCardBody(text: node.body, emphasised: true),
        if (node.actions.isNotEmpty) ...[
          const AppDivider(),
          AiCardActionRow(actions: node.actions, scope: scope),
        ],
      ],
    ),
  );

  static IconData _glyphFor(AiUiTone tone) => switch (tone) {
    AiUiTone.error => Icons.error_outline_rounded,
    AiUiTone.success => Icons.check_circle_outline_rounded,
    AiUiTone.info => Icons.info_outline_rounded,
    _ => Icons.warning_amber_rounded,
  };
}

/// `media_request` — Figma `bottom-sheet` (`7950:29795`).
class AiUiMediaRequestRenderer extends AiNodeRenderer<AiUiMediaRequestNode> {
  /// Creates the renderer.
  const AiUiMediaRequestRenderer();

  @override
  Widget render(
    BuildContext context,
    AiUiMediaRequestNode node,
    AiUiRenderScope scope,
  ) => AiInteractionGate(
    nodeId: node.id,
    ledger: scope.ledger,
    // A declined card stays declined. `AiDismissible` alone cannot promise
    // that any more: answering appends a turn, the conversation list rebuilds,
    // and widget-local state does not survive it. The ledger does.
    builder: (context, state) => state == AiUiNodeInteractionState.cancelled
        ? const SizedBox.shrink()
        : _mediaRequest(context, node, scope),
  );

  Widget _mediaRequest(
    BuildContext context,
    AiUiMediaRequestNode node,
    AiUiRenderScope scope,
  ) => AiDismissible(
    builder: (context, dismiss) => AiSemanticCard(
      semanticsLabel: node.a11yLabel ?? node.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.xxl,
        children: [
          AiPromptHeader(title: node.title, body: node.body),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.md,
            children: [
              for (final option in node.options)
                AiOptionRow(
                  label: option.label,
                  icon: _glyphFor(option.source),
                  // Every option fires the same action with a different
                  // source: the app owns the permission prompt, the picker,
                  // validation and the upload, and the agent only chose what
                  // to offer. The node id travels with it so whatever the
                  // picker returns comes back as a result correlated with
                  // *this* request.
                  onTap: scope.onCapabilityTap(
                    context,
                    nodeId: node.id,
                    action: AiUiAction(
                      type: AiUiActionType.requestImageUpload,
                      params: {'source': option.source.wire},
                    ),
                  ),
                ),
            ],
          ),
          if (node.cancelLabel != null)
            AiPromptButton(
              label: node.cancelLabel!,
              // Backing out is still an answer. The card collapses as it
              // always did, and the agent is told rather than left waiting
              // for a photo that is not coming.
              onTap: () {
                scope.submitInteraction(
                  context,
                  nodeId: node.id,
                  nodeType: AiUiNodeType.mediaRequest,
                  kind: AiUiInteractionKind.mediaResult,
                  status: AiUiInteractionStatus.cancelled,
                  value: const AiUiMediaValue(count: 0),
                );
                dismiss();
              },
            ),
          if (node.actions.isNotEmpty)
            AiCardActionRow(actions: node.actions, scope: scope),
        ],
      ),
    ),
  );

  static IconData _glyphFor(AiUiMediaSource source) => switch (source) {
    AiUiMediaSource.camera => Icons.photo_camera_outlined,
    AiUiMediaSource.gallery => Icons.photo_library_outlined,
    AiUiMediaSource.video => Icons.videocam_outlined,
    AiUiMediaSource.document => Icons.description_outlined,
  };
}

/// `permission_request` — Figma `camera-access-bottom-sheet` (`7950:29810`)
/// and `Location Permission Request` (`7960:31570`).
class AiUiPermissionRequestRenderer
    extends AiNodeRenderer<AiUiPermissionRequestNode> {
  /// Creates the renderer.
  const AiUiPermissionRequestRenderer();

  @override
  Widget render(
    BuildContext context,
    AiUiPermissionRequestNode node,
    AiUiRenderScope scope,
  ) => AiInteractionGate(
    nodeId: node.id,
    ledger: scope.ledger,
    // See the note on `media_request`: a decline that reappeared after the
    // agent replied to it would read as the app ignoring the user.
    builder: (context, state) => state == AiUiNodeInteractionState.cancelled
        ? const SizedBox.shrink()
        : _permissionRequest(context, node, scope),
  );

  Widget _permissionRequest(
    BuildContext context,
    AiUiPermissionRequestNode node,
    AiUiRenderScope scope,
  ) {
    return AiDismissible(
      builder: (context, dismiss) => AiSemanticCard(
        semanticsLabel: node.a11yLabel ?? node.title,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.xxl,
          children: [
            AiPromptHeader(title: node.title, body: node.body),
            if (node.image != null)
              AiMapPreview(
                source: node.image,
                scope: scope,
                nodeType: AiUiNodeType.permissionRequest.wire,
                nodeId: node.id,
              ),
            AiInteractionGate(
              nodeId: node.id,
              ledger: scope.ledger,
              builder: (context, state) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                spacing: AppSpacing.md,
                children: [
                  AiPromptButton(
                    label: node.allowLabel,
                    // Only the app learns how a platform dialog ended, so this
                    // states the intent and the *outcome* comes back through
                    // the capability handler — correlated by the node id the
                    // scope attaches.
                    onTap: scope.onCapabilityTap(
                      context,
                      nodeId: node.id,
                      action: AiUiAction(
                        type: AiUiActionType.requestPermission,
                        params: {'permission': node.permission.wire},
                      ),
                      enabled: state.isInteractive,
                    ),
                  ),
                  if (node.denyLabel != null)
                    // Figma draws the camera variant's decline as a bare text
                    // link and the location variant's as a bordered pill.
                    // Normalised to the pill: a decline that looks like a link
                    // reads as secondary information rather than the equal
                    // choice it is.
                    AiPromptButton(
                      label: node.denyLabel!,
                      filled: false,
                      // A decline needs no platform round trip — the answer is
                      // already known here. It carries no prose: the words for
                      // "you declined" are client copy, and this package holds
                      // no translations, so the host fills them in.
                      onTap: state.isInteractive
                          ? () {
                              scope.submitInteraction(
                                context,
                                nodeId: node.id,
                                nodeType: AiUiNodeType.permissionRequest,
                                kind: AiUiInteractionKind.permissionResult,
                                status: AiUiInteractionStatus.cancelled,
                                value: AiUiPermissionValue(
                                  permission: node.permission.wire,
                                  outcome: AiUiPermissionOutcome.denied,
                                ),
                              );
                              dismiss();
                            }
                          : null,
                    ),
                ],
              ),
            ),
            if (node.actions.isNotEmpty)
              AiCardActionRow(actions: node.actions, scope: scope),
          ],
        ),
      ),
    );
  }
}

/// `location_confirm` — Figma `Location Confirmation` (`7960:31622`).
class AiUiLocationConfirmRenderer
    extends AiNodeRenderer<AiUiLocationConfirmNode> {
  /// Creates the renderer.
  const AiUiLocationConfirmRenderer();

  @override
  Widget render(
    BuildContext context,
    AiUiLocationConfirmNode node,
    AiUiRenderScope scope,
  ) {
    final colors = context.appColors;
    final typography = context.appTypography;
    return AiSemanticCard(
      semanticsLabel: node.a11yLabel ?? '${node.title}. ${node.addressText}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.xl,
        children: [
          AiPromptHeader(title: node.title),
          if (node.image != null)
            AiMapPreview(
              source: node.image,
              scope: scope,
              nodeType: AiUiNodeType.locationConfirm.wire,
              nodeId: node.id,
            ),
          Container(
            padding: EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AiCardTokens.addressRadius),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              spacing: AppSpacing.md,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: AiCardTokens.discGlyphSize,
                  color: AiUiTokens.accent(context),
                ),
                Expanded(
                  child: Text(
                    node.addressText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: typography
                        .semiBold(typography.smallNone)
                        .copyWith(color: colors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
          AiInteractionGate(
            nodeId: node.id,
            ledger: scope.ledger,
            builder: (context, state) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              spacing: AppSpacing.md,
              children: [
                AiPromptButton(
                  label: node.confirmLabel,
                  // The address is still posted verbatim as the user turn —
                  // the agent authored it — and now also as a structured
                  // place, so a confirmation is distinguishable from someone
                  // typing the same words.
                  onTap: state.isInteractive
                      ? () => scope.submitInteraction(
                          context,
                          nodeId: node.id,
                          nodeType: AiUiNodeType.locationConfirm,
                          kind: AiUiInteractionKind.locationConfirmed,
                          value: AiUiLocationValue(
                            name: node.addressText,
                            source: AiUiLocationSource.saved,
                          ),
                          text: node.addressText,
                        )
                      : null,
                ),
                if (node.changeLabel != null)
                  AiPromptButton(
                    label: node.changeLabel!,
                    filled: false,
                    onTap: scope.onCapabilityTap(
                      context,
                      nodeId: node.id,
                      action: const AiUiAction(
                        type: AiUiActionType.requestLocationShare,
                      ),
                      enabled: state.isInteractive,
                    ),
                  ),
              ],
            ),
          ),
          if (node.actions.isNotEmpty)
            AiCardActionRow(actions: node.actions, scope: scope),
        ],
      ),
    );
  }
}
