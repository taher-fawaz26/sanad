import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/entities/ai_chat_suggestion.dart';

/// Tappable starter prompts, shown above the composer before a conversation
/// starts — Figma `quick-suggestions` (`5153:42722`).
///
/// Figma stacks these **vertically**, one per row, each pill hugging its own
/// text at the row's start — not flowed side by side. A `Wrap` put two short
/// prompts on one line and turned a deliberately calm, list-like stack into a
/// row of buttons, so this is a `Column` of full-width rows instead: the row
/// carries the alignment, the pill carries the size.
///
/// Stateless and inert on its own: a tap only calls [onSelected], carrying no
/// business logic of its own — sending the suggested text, exactly like any
/// other composer send, is the caller's job.
class AiChatSuggestions extends StatelessWidget {
  /// Creates the stack for [suggestions].
  const AiChatSuggestions({
    required this.suggestions,
    required this.onSelected,
    super.key,
  });

  /// Vertical gap between prompts — Figma `5153:42722` (`gap-[10px]`), which
  /// falls between `AppSpacing.sm` and `.md`.
  static const _rowGap = 10.0;

  /// The prompts to show, in order.
  final List<AiChatSuggestion> suggestions;

  /// Fired when a prompt is tapped.
  final ValueChanged<AiChatSuggestion> onSelected;

  @override
  Widget build(BuildContext context) {
    // Subscribes this widget to the app locale so a language change rebuilds
    // it. Home lives in a `StatefulShellRoute.indexedStack`, which keeps the
    // branch mounted — so without a dependency on the locale the pills kept
    // whatever language they were first built in, and an Arabic UI went on
    // showing English prompts (visible as "?When does my passport expire",
    // English text laid out RTL). Only reachable at all since Account
    // Settings gained an entry point (C-11).
    //
    // `Localizations.localeOf` rather than easy_localization's `context.locale`
    // so the dependency also exists under a bare `MaterialApp` — the widget
    // tests pump this without an EasyLocalization ancestor, and that extension
    // throws there.
    Localizations.localeOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: _rowGap,
      children: [
        for (final suggestion in suggestions)
          // A full-width row whose child hugs its text: this is what keeps the
          // pill start-aligned (and therefore correctly mirrored under RTL)
          // without stretching it to the row's width.
          Align(
            key: ValueKey(suggestion.id),
            alignment: AlignmentDirectional.centerStart,
            child: _SuggestionPill(
              label: suggestion.labelKey.tr(),
              onTap: () => onSelected(suggestion),
            ),
          ),
      ],
    );
  }
}

/// One prompt — Figma `suggestion-pill` (`5153:42724`).
///
/// Client-local rather than `AppChip`: the chip component is built for
/// selectable filters and brings its own height, radius, padding and
/// selected/outline treatments. This is an unselectable one-shot prompt with
/// Figma's own 16/10 padding on a fully-rounded white pill, and bending
/// `AppChip` to match would have meant either a visual miss here or new
/// variants that every other chip in both apps would then inherit.
class _SuggestionPill extends StatelessWidget {
  const _SuggestionPill({required this.label, required this.onTap});

  /// Figma `px-[16px] py-[10px]`. The vertical value has no `AppSpacing`
  /// token, so both are stated here together rather than splitting one pair
  /// of Figma numbers across a token and a literal.
  static const _paddingH = 16.0;
  static const _paddingV = 10.0;

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = BorderRadius.circular(100);

    return Material(
      color: colors.surface,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: _paddingH,
            vertical: _paddingV,
          ),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: colors.border),
          ),
          child: Text(
            label,
            style: context.appTypography.smallNormal.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
