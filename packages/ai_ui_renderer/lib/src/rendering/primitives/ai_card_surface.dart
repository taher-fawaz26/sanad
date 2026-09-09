import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/src/rendering/ai_card_tokens.dart';
import 'package:ai_ui_renderer/src/rendering/ai_ui_render_scope.dart';
import 'package:ai_ui_renderer/src/rendering/ai_ui_tokens.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// The surface every AI semantic card sits on — Figma's shared card shell.
///
/// Deliberately **not** `AppSectionCard`, which every other section in both
/// apps uses: that component fills with `colors.background`, hardcodes a 12dp
/// radius, has no border option and forces `AppSpacing.lg` between its
/// children. Figma's AI card is white on a hairline border at 16dp with its own
/// gaps, and none of those four properties is configurable — so composing it
/// would mean either missing the design or changing a component that a dozen
/// settings screens depend on.
///
/// One `Semantics(button: true, container: true)` when tappable, and **always**
/// its own `Material` so it never depends on what it happens to be rendered
/// inside — the same two rules `AiUiCardRenderer` already follows.
///
/// The Material is unconditional, not tied to tappability: the interactive
/// cards put a `TextField` inside an *untappable* card, and a text field with
/// no Material ancestor throws during layout.
class AiSemanticCard extends StatelessWidget {
  /// Creates the shell.
  const AiSemanticCard({
    required this.child,
    required this.semanticsLabel,
    this.onTap,
    this.borderTone,
    this.emphasised = false,
    this.panel = false,
    super.key,
  });

  /// The card's content, already laid out as a column by the caller.
  final Widget child;

  /// Announced in place of walking the card's children.
  final String semanticsLabel;

  /// `null` leaves the card inert rather than tappable and doing nothing.
  final VoidCallback? onTap;

  /// Tints the border — a `reminder_card`'s warning edge, a selected
  /// `service_card`'s accent. `null` keeps the neutral hairline.
  final AiUiTone? borderTone;

  /// Draws the border at Figma's 1.5dp instead of a hairline. Set together
  /// with [borderTone] for a card the design calls out.
  final bool emphasised;

  /// The `request_summary` treatment: a rounder corner and a lift.
  final bool panel;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = BorderRadius.circular(
      panel ? AiCardTokens.panelRadius : AiCardTokens.cardRadius,
    );
    final borderColor = borderTone == null
        ? colors.border
        : AiUiTokens.toneContainer(context, borderTone!);

    final decorated = Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(
          color: borderColor,
          width: emphasised
              ? AiCardTokens.emphasisBorderWidth
              : AppDimension.borderHairline,
        ),
      ),
      child: child,
    );

    // The fill, the lift and the clip live on the Material rather than the
    // Container so an ink splash stays inside the card's own corners.
    final card = Material(
      color: colors.surface,
      borderRadius: radius,
      shadowColor: Colors.transparent,
      child: onTap == null
          ? decorated
          : InkWell(onTap: onTap, borderRadius: radius, child: decorated),
    );

    final lifted = panel
        ? DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: AiCardTokens.panelShadow,
            ),
            child: card,
          )
        : card;

    if (onTap == null) return lifted;

    return Semantics(
      label: semanticsLabel,
      button: true,
      container: true,
      child: lifted,
    );
  }
}

/// A semantic card's attached row of buttons — Figma's in-card `action-group`.
///
/// Equal-width and 44dp tall, which is shorter than `AppButtonSize.block`
/// because these sit *inside* a card rather than under one. `AppButton` cannot
/// express that height (its size tiers are fixed at 48/48/32), so the row draws
/// its own buttons from the same tokens `AppButton` resolves — variant and
/// intent still come from the protocol's own vocabulary.
class AiCardActionRow extends StatelessWidget {
  /// Creates the row for [actions]; renders nothing when it is empty.
  const AiCardActionRow({
    required this.actions,
    required this.scope,
    super.key,
  });

  /// Already validated: an entry whose action could not be resolved was
  /// dropped before this point.
  final List<AiUiCardAction> actions;
  final AiUiRenderScope scope;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    return Row(
      spacing: AppSpacing.md,
      children: [
        for (final entry in actions)
          Expanded(
            child: AiCardButton(
              label: entry.label,
              variant: entry.variant,
              intent: entry.intent,
              onTap: scope.onTapFor(context, entry.action),
            ),
          ),
      ],
    );
  }
}

/// One button inside a card's action row.
///
/// The four protocol variants map onto Figma's three in-card treatments:
/// filled accent, tonal neutral, and accent outline. `transparent` collapses
/// onto the outline's colours without its border, which is the only reading
/// that stays legible on a white card.
class AiCardButton extends StatelessWidget {
  /// Creates the button.
  const AiCardButton({
    required this.label,
    required this.onTap,
    this.variant = AiUiButtonVariant.primary,
    this.intent = AiUiButtonIntent.standard,
    this.compact = false,
    super.key,
  });

  final String label;
  final VoidCallback? onTap;
  final AiUiButtonVariant variant;
  final AiUiButtonIntent intent;

  /// Shorter, for a button that sits beside content instead of on its own row.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = intent == AiUiButtonIntent.destructive
        ? colors.error
        : AiUiTokens.accent(context);
    final radius = BorderRadius.circular(AiCardTokens.cardButtonRadius);

    final (background, foreground, borderColor) = switch (variant) {
      AiUiButtonVariant.primary => (accent, colors.palettes.dark.shade50, null),
      // Figma's `sky/100` on `sky/900`, which is what `neutral` means on this
      // surface — a recessive control beside an accented one.
      AiUiButtonVariant.secondary => (
        colors.palettes.sky.shade100,
        colors.palettes.sky.shade900,
        null,
      ),
      AiUiButtonVariant.outline => (Colors.transparent, accent, accent),
      AiUiButtonVariant.transparent => (Colors.transparent, accent, null),
    };

    return Semantics(
      button: true,
      enabled: onTap != null,
      child: Material(
        color: background,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            height: compact
                ? AiCardTokens.inlineButtonHeight
                : AiCardTokens.cardButtonHeight,
            alignment: Alignment.center,
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: borderColor == null
                  ? null
                  : Border.all(
                      color: borderColor,
                      width: AiCardTokens.emphasisBorderWidth,
                    ),
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: context.appTypography
                  .semiBold(
                    context.appTypography.smallNone,
                  )
                  .copyWith(color: foreground),
            ),
          ),
        ),
      ),
    );
  }
}

/// The full-width call to action on a prompt card — Figma's 48dp pill.
///
/// `AppButton(size: block)` matches its height and radius exactly but resolves
/// `main/600` for a primary fill, where every AI frame specifies `main/700`.
/// Rather than restyle every CTA in both apps, this draws `AppButton`'s
/// geometry and typography with the AI surface's own accent.
class AiPromptButton extends StatelessWidget {
  /// Creates the button.
  const AiPromptButton({
    required this.label,
    required this.onTap,
    this.filled = true,
    super.key,
  });

  final String label;
  final VoidCallback? onTap;

  /// `false` renders Figma's secondary option — a bordered pill with muted
  /// text.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = BorderRadius.circular(AppDimension.radiusPill);
    final typography = context.appTypography;

    return Semantics(
      button: true,
      enabled: onTap != null,
      child: Material(
        color: filled ? AiUiTokens.accent(context) : Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            width: double.infinity,
            height: AiCardTokens.promptButtonHeight,
            alignment: Alignment.center,
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.xxl,
            ),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: filled ? null : Border.all(color: colors.border),
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: filled
                  ? typography.labelLarge.copyWith(
                      color: colors.palettes.dark.shade50,
                    )
                  : typography
                        .semiBold(typography.regularNone)
                        .copyWith(color: colors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}

/// Lets a prompt card be dismissed without an action.
///
/// Declining a prompt — "Not now", "Don't allow", "Cancel" — is a *client*
/// concern: the card collapses, and the agent learns the answer from what the
/// user does next rather than from a dispatched intent. That is also why the
/// protocol's `dismiss` action stays unimplemented: there is nothing for a
/// handler to do that the widget cannot do itself.
///
/// A wrapper rather than state on each renderer, so the renderers stay
/// const-constructible and stateless.
class AiDismissible extends StatefulWidget {
  /// Creates the wrapper. [builder] receives the callback that collapses it.
  const AiDismissible({required this.builder, super.key});

  /// Builds the content, given the dismiss callback to wire to its decline
  /// control.
  final Widget Function(BuildContext context, VoidCallback dismiss) builder;

  @override
  State<AiDismissible> createState() => _AiDismissibleState();
}

class _AiDismissibleState extends State<AiDismissible> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) => _dismissed
      ? const SizedBox.shrink()
      : widget.builder(context, () => setState(() => _dismissed = true));
}
