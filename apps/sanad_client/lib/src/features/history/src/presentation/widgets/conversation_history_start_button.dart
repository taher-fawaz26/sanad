import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/composer/ai_composer_tokens.dart';

/// The empty state's call to action — Figma `Controls / Buttons` as the
/// History screen instances it (`8124:3954`).
///
/// Geometry, typography and label colour are [AppButton]'s exactly: a 48dp
/// block on [AppDimension.radiusPill], `labelLarge` (16dp Medium) in
/// `dark/50`. What differs is the fill, and only the fill — Figma specifies
/// `#1A7E6B` (`main/700`), where [AppButton]'s primary variant resolves
/// `main/600` (`#26A68C`).
///
/// That is not a Figma slip: it is the AI surface's own green, the same one
/// `AiComposerTokens.accent` documents for the composer's Send pill, focused
/// border and caret. Every AI Chat frame specifies the darker shade, so this
/// screen's CTA follows the surface it belongs to.
///
/// A client-local button rather than a change to [AppButton] or to
/// `AppColors.primary`: repointing either would restyle every CTA in both
/// apps to fix one screen. And rather than a `Theme` that swaps the main
/// palette's 600 for its 700 under this subtree — which would reach
/// [AppButton]'s fill by overriding a palette *index*, an indirection nobody
/// reading the call site could follow.
class ConversationHistoryStartButton extends StatefulWidget {
  /// Creates the button.
  const ConversationHistoryStartButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  /// The button's text.
  final String label;

  /// Fired on tap.
  final VoidCallback onPressed;

  @override
  State<ConversationHistoryStartButton> createState() =>
      _ConversationHistoryStartButtonState();
}

class _ConversationHistoryStartButtonState
    extends State<ConversationHistoryStartButton> {
  /// Figma `h-[48px]` — the same block height `AppButtonSize.block` resolves.
  static const double _height = 48;

  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = BorderRadius.circular(AppDimension.radiusPill);

    return Semantics(
      button: true,
      child: Material(
        // One step darker while held, mirroring the primary variant's own
        // default→pressed move down the palette.
        color: _pressed
            ? colors.palettes.main.shade800
            : AiComposerTokens.accent(context),
        shape: RoundedRectangleBorder(borderRadius: radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onPressed,
          onHighlightChanged: (value) => setState(() => _pressed = value),
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          child: SizedBox(
            width: double.infinity,
            height: responsiveDimension(_height),
            child: Center(
              child: Padding(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                child: Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  // Figma: 16dp Medium in `dark/50` (`#F9F9FA`) — which is
                  // what `labelLarge` and the primary variant's foreground
                  // already resolve to.
                  style: context.appTypography.labelLarge.copyWith(
                    color: colors.palettes.dark.shade50,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
