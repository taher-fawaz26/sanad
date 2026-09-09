import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
// `show Bidi`: intl exports a `TextDirection` of its own, which would
// shadow Flutter's.
import 'package:intl/intl.dart' show Bidi;
import 'package:sanad_client/src/features/history/src/domain/conversation_history_entry.dart';
import 'package:sanad_client/src/features/history/src/presentation/conversation_history_time_formatter.dart';
import 'package:sanad_client/src/features/history/src/presentation/conversation_history_tokens.dart';

/// One past conversation — Figma's history card (`8102:35064`).
///
/// Client-local rather than a shared card component, for the same reason
/// `AiChatSuggestions`' pill is: the shared cards bring their own radius,
/// padding and elevation, and Figma specifies a 20dp radius on a 16dp inset
/// with a hairline border and no shadow. Bending a shared card to that would
/// have meant either missing the design here or adding variants every other
/// card in both apps would inherit.
///
/// Flat white, not glass: Figma draws an opaque surface with a border, and a
/// list of glass cards would mean one `BackdropFilter` per row.
class ConversationHistoryCard extends StatelessWidget {
  /// Creates the card for [entry].
  const ConversationHistoryCard({
    required this.entry,
    required this.onTap,
    super.key,
  });

  /// The conversation to draw.
  final ConversationHistoryEntry entry;

  /// Fired when the card is tapped.
  final VoidCallback onTap;

  /// The most of the header row the timestamp may take before it ellipsizes.
  ///
  /// A ceiling, not a share: the caption needs roughly a third of the row at
  /// Figma's own sizes, so this never binds until the text scale pushes it
  /// past — and when it does, the title keeps the rest of the row instead of
  /// being squeezed to nothing by a caption nobody needs in full.
  static const double _timestampMaxFraction = 0.6;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final radius = BorderRadius.circular(
      responsiveDimension(ConversationHistoryTokens.cardRadius),
    );

    return Material(
      color: colors.surface,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          // Figma `p-[16px]`.
          padding: EdgeInsetsDirectional.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: radius,
            // Figma's `#E8ECEB` hairline — the design system's `border`.
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            // Figma `gap-[12px]` between the header row and the preview.
            spacing: AppSpacing.md,
            children: [
              // The row is measured so the timestamp can be *bounded*. Figma
              // sets both halves to hug their text (`justify-between`), which
              // in Flutter means the title expands and the timestamp does
              // not — correct until the user's text scale makes the timestamp
              // alone wider than the card, at which point an inflexible child
              // overflows the row. Capping it at [_timestampMaxFraction]
              // costs nothing at any normal size, where the cap is far wider
              // than the caption needs.
              LayoutBuilder(
                builder: (context, constraints) => Row(
                  children: [
                    // Takes the width the timestamp does not, so a title
                    // longer than the row ellipsizes instead of pushing the
                    // timestamp out of the card.
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        // Figma `gap-[8px]` between glyph and title.
                        spacing: AppSpacing.sm,
                        children: [
                          // Baked brand colours (`#1A7E6B` + `#87FC00`), so no
                          // `colorFilter` — the same export the composer's
                          // leading glyph uses, at Figma's 16dp here.
                          AppSvgPicture.asset(
                            AppSvgs.aiChatSparkle,
                            width: responsiveDimension(
                              ConversationHistoryTokens.cardGlyphSize,
                            ),
                            height: responsiveDimension(
                              ConversationHistoryTokens.cardGlyphSize,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              entry.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textDirection: _autoDirection(entry.title),
                              // Figma: 16dp SemiBold `#111827`.
                              style: typography.regularNone.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth * _timestampMaxFraction,
                      ),
                      child: Text(
                        ConversationHistoryTimeFormatter.format(
                          entry.updatedAt,
                          // `Localizations.localeOf`, as `AiUiFormatters` reads
                          // it on this same surface — not easy_localization's
                          // `context.locale`, which is unavailable to a subtree
                          // without an `EasyLocalization` ancestor (a widget
                          // test, most of all) and carries the same value.
                          locale: Localizations.localeOf(context).toString(),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        // Figma: 12dp Regular `#6B7370`.
                        style: typography.tinyNone.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                entry.preview,
                maxLines: ConversationHistoryTokens.cardPreviewMaxLines,
                overflow: TextOverflow.ellipsis,
                textDirection: _autoDirection(entry.preview),
                // Figma: 14dp Regular on a 20dp line — exactly the design
                // system's `small`/`normal` pairing.
                style: typography.smallNormal.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Figma's `dir="auto"` on the card's title and preview, which the design sets
/// on every string a conversation supplies.
///
/// Conversation content is not necessarily in the app's language: an Arabic UI
/// can hold a conversation about an English-named service, and inheriting the
/// page's RTL for that paragraph pushes its sentence-final punctuation to the
/// visual left. Resolving each string's own direction from its first strong
/// character is what a browser does for `dir="auto"`, and what
/// `Bidi.detectRtlDirectionality` does here.
///
/// Not `String.ltrIsolated`: that is for an inherently-LTR *value* embedded in
/// surrounding text (a phone number, a URL). These are whole paragraphs on
/// their own lines, where the correct treatment is a paragraph direction
/// rather than an isolate.
TextDirection _autoDirection(String text) =>
    Bidi.detectRtlDirectionality(text) ? TextDirection.rtl : TextDirection.ltr;
