import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/src/interaction/ai_interaction_gate.dart';
import 'package:ai_ui_renderer/src/rendering/ai_card_tokens.dart';
import 'package:ai_ui_renderer/src/rendering/ai_node_renderer.dart';
import 'package:ai_ui_renderer/src/rendering/ai_ui_render_scope.dart';
import 'package:ai_ui_renderer/src/rendering/primitives/ai_card_content.dart';
import 'package:ai_ui_renderer/src/rendering/primitives/ai_card_surface.dart';
import 'package:ai_ui_renderer/src/rendering/primitives/ai_prompt_parts.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// The cards the user answers.
///
/// All four share one contract: the agent supplies a **template**, the widget
/// holds what the user chose or typed, and confirming submits *both* halves of
/// the answer — the sentence the template produces, and a typed
/// `AiUiInteraction` naming the node, the choice and the message that asked.
///
/// The sentence is what the conversation reads like and what a backend that
/// has not implemented results still understands; the interaction is what
/// spares the agent from re-parsing its own prose. Neither can post text the
/// agent did not author: the template is still the only source of the words.
///
/// Both travel through `AiUiRenderScope.submitInteraction`, which is also the
/// only place a second tap is stopped — the ledger has to accept the node
/// before anything is built. That replaced a `_submitted` flag that guarded
/// exactly one of these three cards.
///
/// Three of them are the only `StatefulWidget`s in the renderer, following the
/// `_AiUiRichText` precedent: they own a controller or a selection and dispose
/// it. Everything else in this package stays a const stateless renderer, so a
/// streaming token still rebuilds nothing but the bubble being written.

/// Replaces the one `{placeholder}` a template may carry.
///
/// A template with no placeholder is sent verbatim, which is what makes "post
/// a fixed message" expressible without a second field. Nothing else in the
/// template is interpreted.
String applyTemplate(String template, String placeholder, String value) =>
    template.replaceAll('{$placeholder}', value);

/// `quick_reply` — Figma `QuickRepliesContainer` (`7866:8315`).
///
/// A tapped option whose action is `send_message` becomes a
/// `quick_reply_selected` result, so the agent learns *which* suggestion was
/// taken rather than having to match on the sentence. Any other action stays a
/// plain dispatch: an option that opens a service is navigation, not an answer.
class AiUiQuickReplyRenderer extends AiNodeRenderer<AiUiQuickReplyNode> {
  /// Creates the renderer.
  const AiUiQuickReplyRenderer();

  @override
  Widget render(
    BuildContext context,
    AiUiQuickReplyNode node,
    AiUiRenderScope scope,
  ) => AiInteractionGate(
    nodeId: node.id,
    ledger: scope.ledger,
    builder: (context, state) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.sm,
      children: [
        for (final (index, option) in node.options.indexed)
          _QuickReplyPill(
            label: option.label,
            accented: index == 0,
            onTap: state.isInteractive
                ? () => _tap(context, node, option, scope)
                : null,
          ),
      ],
    ),
  );

  void _tap(
    BuildContext context,
    AiUiQuickReplyNode node,
    AiUiQuickReplyOption option,
    AiUiRenderScope scope,
  ) {
    if (option.action.type != AiUiActionType.sendMessage) {
      scope.actions.dispatch(context, option.action);
      return;
    }

    scope.submitInteraction(
      context,
      nodeId: node.id,
      nodeType: AiUiNodeType.quickReply,
      kind: AiUiInteractionKind.quickReplySelected,
      value: AiUiSelectionValue(label: option.label),
      text: option.action.text,
    );
  }
}

/// One suggested reply.
class _QuickReplyPill extends StatelessWidget {
  const _QuickReplyPill({
    required this.label,
    required this.accented,
    this.onTap,
  });

  final String label;
  final bool accented;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final accent = colors.palettes.main.shade700;
    final radius = BorderRadius.circular(AppDimension.radiusPill);

    return Semantics(
      button: true,
      enabled: onTap != null,
      child: Material(
        type: MaterialType.transparency,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            alignment: Alignment.center,
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: accented ? accent : colors.palettes.dark.shade300,
                width: accented
                    ? AiCardTokens.emphasisBorderWidth
                    : AppDimension.borderHairline,
              ),
            ),
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style:
                  (accented
                          ? typography.semiBold(typography.smallNone)
                          : typography.medium(typography.smallNone))
                      .copyWith(
                        color: accented ? accent : colors.textSecondary,
                      ),
            ),
          ),
        ),
      ),
    );
  }
}

/// `time_slots` — Figma `slots-card` (`8015:29542`).
class AiUiTimeSlotsRenderer extends AiNodeRenderer<AiUiTimeSlotsNode> {
  /// Creates the renderer.
  const AiUiTimeSlotsRenderer();

  @override
  Widget render(
    BuildContext context,
    AiUiTimeSlotsNode node,
    AiUiRenderScope scope,
  ) => _TimeSlots(node: node, scope: scope, key: ValueKey(node.id));
}

class _TimeSlots extends StatefulWidget {
  const _TimeSlots({required this.node, required this.scope, super.key});

  final AiUiTimeSlotsNode node;
  final AiUiRenderScope scope;

  @override
  State<_TimeSlots> createState() => _TimeSlotsState();
}

class _TimeSlotsState extends State<_TimeSlots> {
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.node.selectedSlotId;
  }

  void _submit() {
    final node = widget.node;
    final slot = node.slots.firstWhere((s) => s.id == _selectedId);

    widget.scope.submitInteraction(
      context,
      nodeId: node.id,
      nodeType: AiUiNodeType.timeSlots,
      kind: AiUiInteractionKind.slotSelected,
      // The slot's own id travels alongside its label so the agent resolves
      // the booking by identifier and never by matching display text.
      value: AiUiSelectionValue(id: slot.id, label: slot.label),
      text: applyTemplate(node.confirmTemplate, 'slot', slot.label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.node;

    return AiSemanticCard(
      semanticsLabel: node.a11yLabel ?? node.dateLabel ?? node.confirmLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.lg,
        children: [
          if (node.dateLabel != null)
            AiIconRow(
              icon: Icons.calendar_today_outlined,
              text: node.dateLabel!,
              emphasised: true,
            ),
          AiInteractionGate(
            nodeId: node.id,
            ledger: widget.scope.ledger,
            builder: (context, state) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              spacing: AppSpacing.lg,
              children: [
                AiSlotGrid(
                  slots: node.slots,
                  selectedId: _selectedId,
                  onSelected: (slot) {
                    // Once the answer has gone the grid is a record of what
                    // was chosen, not a control.
                    if (!state.isInteractive) return;
                    setState(() => _selectedId = slot.id);
                  },
                ),
                AiCardButton(
                  label: node.confirmLabel,
                  // Disabled until a slot is chosen — confirming nothing would
                  // post a template with an empty substitution — and after the
                  // answer has gone, so a second tap cannot book twice.
                  onTap: _selectedId == null || !state.isInteractive
                      ? null
                      : _submit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// `review_request` — Figma `review-card` (`8015:29490`).
class AiUiReviewRequestRenderer extends AiNodeRenderer<AiUiReviewRequestNode> {
  /// Creates the renderer.
  const AiUiReviewRequestRenderer();

  @override
  Widget render(
    BuildContext context,
    AiUiReviewRequestNode node,
    AiUiRenderScope scope,
  ) => _ReviewRequest(node: node, scope: scope, key: ValueKey(node.id));
}

class _ReviewRequest extends StatefulWidget {
  const _ReviewRequest({required this.node, required this.scope, super.key});

  final AiUiReviewRequestNode node;
  final AiUiRenderScope scope;

  @override
  State<_ReviewRequest> createState() => _ReviewRequestState();
}

class _ReviewRequestState extends State<_ReviewRequest> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final node = widget.node;
    final comment = _controller.text.trim();

    widget.scope.submitInteraction(
      context,
      nodeId: node.id,
      nodeType: AiUiNodeType.reviewRequest,
      kind: AiUiInteractionKind.reviewSubmitted,
      // An empty comment is a legitimate answer, and the agent is told so
      // rather than left waiting for words that are not coming.
      value: AiUiTextValue(comment),
      text: applyTemplate(node.submitTemplate, 'comment', comment),
    );
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final colors = context.appColors;

    return AiSemanticCard(
      semanticsLabel: node.a11yLabel ?? node.serviceName,
      child: AiInteractionGate(
        nodeId: node.id,
        ledger: widget.scope.ledger,
        builder: (context, state) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.lg,
          children: [
            AiCardHeader(title: node.serviceName, subtitle: node.providerText),
            // A fixed-height box rather than `AppTextField`: that component
            // brings its own 48dp height, label slot and trailing affordances,
            // and Figma's comment area is a 150dp region with nothing but a
            // placeholder.
            Container(
              height: AiCardTokens.commentBoxHeight,
              padding: EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AiCardTokens.tileRadius),
                border: Border.all(color: colors.border),
              ),
              child: TextField(
                controller: _controller,
                enabled: state.isInteractive,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                maxLength: node.maxCommentLength,
                style: context.appTypography.smallNormal.copyWith(
                  color: colors.textPrimary,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  isCollapsed: true,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  counterText: '',
                  constraints: const BoxConstraints(),
                  contentPadding: EdgeInsets.zero,
                  hintText: node.commentPlaceholder,
                  hintStyle: context.appTypography.smallNormal.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ),
            AiCardButton(
              label: node.submitLabel,
              // One submission per card: the review has been posted as a user
              // turn, and a second tap would post it again.
              onTap: state.isInteractive ? _submit : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// `location_picker` — Figma `Choose Location` (`7960:31584`).
class AiUiLocationPickerRenderer
    extends AiNodeRenderer<AiUiLocationPickerNode> {
  /// Creates the renderer.
  const AiUiLocationPickerRenderer();

  @override
  Widget render(
    BuildContext context,
    AiUiLocationPickerNode node,
    AiUiRenderScope scope,
  ) => _LocationPicker(node: node, scope: scope, key: ValueKey(node.id));
}

class _LocationPicker extends StatefulWidget {
  const _LocationPicker({required this.node, required this.scope, super.key});

  final AiUiLocationPickerNode node;
  final AiUiRenderScope scope;

  @override
  State<_LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<_LocationPicker> {
  late final TextEditingController _searchController;
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// The place the confirm button would send: a typed query wins over a
  /// selected saved place, because typing is the more recent intent.
  ///
  /// Returns the structured answer rather than a bare string, so the agent
  /// receives the saved place's own id when there is one and can tell a
  /// remembered place from free text.
  AiUiLocationValue? get _value {
    final typed = _searchController.text.trim();
    if (typed.isNotEmpty) {
      return AiUiLocationValue(name: typed, source: AiUiLocationSource.typed);
    }

    final id = _selectedId;
    if (id == null) return null;

    final place = widget.node.savedLocations.firstWhere((p) => p.id == id);
    return AiUiLocationValue(
      id: place.id,
      name: place.name,
      addressText: place.addressText,
      source: AiUiLocationSource.saved,
    );
  }

  void _submit() {
    final value = _value;
    if (value == null) return;

    widget.scope.submitInteraction(
      context,
      nodeId: widget.node.id,
      nodeType: AiUiNodeType.locationPicker,
      kind: AiUiInteractionKind.locationSelected,
      value: value,
      text: applyTemplate(
        widget.node.confirmTemplate,
        'location',
        value.name,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final colors = context.appColors;
    final typography = context.appTypography;

    return AiSemanticCard(
      semanticsLabel: node.a11yLabel ?? node.title,
      child: AiInteractionGate(
        nodeId: node.id,
        ledger: widget.scope.ledger,
        builder: (context, state) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.xl,
          children: [
            AiPromptHeader(title: node.title),
            if (node.searchPlaceholder != null)
              // A real field, not a decorative one. Searching *places* would
              // need a places API this layer has no business reaching, so what
              // the user types becomes the answer instead: it fills the same
              // `{location}` slot a saved place would, and the agent resolves
              // it in the conversation. The shared search bar handles the
              // focus, clear affordance and RTL for free.
              AppSearchField(
                controller: _searchController,
                hint: node.searchPlaceholder!,
                variant: AppSearchFieldVariant.bordered,
                showMicIcon: false,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _submit(),
              ),
            if (node.useCurrentLabel != null)
              AiOptionRow(
                label: node.useCurrentLabel!,
                icon: Icons.my_location_rounded,
                accented: true,
                // The app owns the device: this states an intent and the
                // result comes back through the capability handler, correlated
                // by the node id the scope attaches.
                onTap: widget.scope.onCapabilityTap(
                  context,
                  nodeId: node.id,
                  action: const AiUiAction(
                    type: AiUiActionType.requestLocationShare,
                  ),
                  enabled: state.isInteractive,
                ),
              ),
            if (node.savedLocations.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                spacing: AppSpacing.sm,
                children: [
                  if (node.savedLabel != null)
                    Text(
                      node.savedLabel!.toUpperCase(),
                      style: typography
                          .bold(typography.tinyNone)
                          .copyWith(color: colors.textMuted),
                    ),
                  for (final place in node.savedLocations)
                    AiOptionRow(
                      key: ValueKey(place.id),
                      label: place.name,
                      subtitle: place.addressText,
                      icon: Icons.location_on_outlined,
                      selected: place.id == _selectedId,
                      onTap: state.isInteractive
                          ? () => setState(() => _selectedId = place.id)
                          : null,
                    ),
                ],
              ),
            AiPromptButton(
              label: node.confirmLabel,
              // Disabled until there is something to send — a typed query or a
              // chosen saved place — and after the answer has gone.
              onTap: _value == null || !state.isInteractive ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
