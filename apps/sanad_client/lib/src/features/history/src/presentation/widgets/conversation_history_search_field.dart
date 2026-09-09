import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/composer/ai_composer_tokens.dart';
import 'package:sanad_client/src/features/history/src/presentation/conversation_history_tokens.dart';

/// Conversation History's search box — Figma `8102:35060`.
///
/// This is the shared [AppSearchField], not a second search widget. What it
/// adds is Figma's *spec*: a 52dp field on a 16dp radius with a 20dp glyph
/// and 14dp type, where the shared bar resolves 40dp / 8dp / 22dp / 16dp for
/// every other screen in both apps.
///
/// The spec arrives through a scoped [Theme], because that is where
/// [AppSearchField] already reads it from — `AppSearchBarTheme` is a
/// `ThemeExtension`, so overriding it for this subtree changes nothing
/// anywhere else and needs no new parameters on the shared component. The one
/// property the extension cannot reach is the bordered variant's glyph size,
/// which is why [AppSearchField.iconSize] exists.
///
/// Not glass: Figma draws a flat white field with a hairline border here, the
/// same as the cards below it, so `ClientGlassSurface` would add a blur pass
/// for a surface the design says is opaque.
class ConversationHistorySearchField extends StatelessWidget {
  /// Creates the field.
  const ConversationHistorySearchField({
    required this.controller,
    required this.onChanged,
    super.key,
  });

  /// Owns the query text, so the page can read and clear it.
  final TextEditingController controller;

  /// Fired on every keystroke with the current query.
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(
        extensions: [
          ...theme.extensions.values,
          AppSearchBarTheme(spec: _spec(context)),
        ],
      ),
      child: AppSearchField(
        controller: controller,
        onChanged: onChanged,
        hint: 'history.search_hint'.tr(),
        variant: AppSearchFieldVariant.bordered,
        // Figma has no trailing control on this field — the shared bar's
        // default mic belongs to the browse/search screens it was built for.
        showMicIcon: false,
        iconSize: responsiveDimension(
          ConversationHistoryTokens.searchIconSize,
        ),
      ),
    );
  }

  /// Figma's own numbers, run through the same responsive engine the shared
  /// resolver uses so the field scales with the rest of the page.
  ///
  /// `backgroundColor` and the border are absent on purpose: the bordered
  /// variant takes both from `FieldTokens` (white on a
  /// `field/border-default` hairline), which is already what Figma draws.
  static SearchBarStyleSpec _spec(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final resolved = context.appSearchBarTheme.spec;

    final base = typography.smallNormal.copyWith(
      fontSize: ConversationHistoryTokens.searchFontSize.rfs,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
    );

    return SearchBarStyleSpec(
      height: responsiveDimension(ConversationHistoryTokens.searchHeight),
      borderRadius: BorderRadius.circular(
        responsiveDimension(ConversationHistoryTokens.searchRadius),
      ),
      backgroundColor: colors.surface,
      // Figma strokes the glyph near-black (`#131927`), which is what the
      // shared resolver already picks for light mode.
      iconColor: resolved.iconColor,
      hintStyle: base.copyWith(color: colors.textSecondary),
      valueStyle: base.copyWith(color: colors.textPrimary),
      cancelStyle: base.copyWith(color: colors.textPrimary),
      // The AI surface's darker green, as on the composer's caret — see
      // `AiComposerTokens.accent`.
      cursorColor: AiComposerTokens.accent(context),
      iconSize: responsiveDimension(
        ConversationHistoryTokens.searchIconSize,
      ),
      iconPadding: responsiveDimension(
        ConversationHistoryTokens.searchIconPadding,
      ),
      iconGap: responsiveDimension(ConversationHistoryTokens.searchIconGap),
      // Unreachable here — `showCancelOnFocus` is off, and Figma has no
      // Cancel affordance on this screen. Carried over rather than invented
      // so the spec stays complete.
      cancelGap: resolved.cancelGap,
      cancelAreaWidth: resolved.cancelAreaWidth,
    );
  }
}
