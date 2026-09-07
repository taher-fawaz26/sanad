import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Renders the **bounded** Markdown subset the live agent actually emits
/// inside `text` nodes.
///
/// The production agent writes prose with `**bold**`, `### headings`, `- `
/// bullets and `1.` numbered lists. Protocol v1 renders `text` verbatim, so
/// without this the user would read literal asterisks and hashes.
///
/// ## Why a subset and not a Markdown package
///
/// A general Markdown renderer also renders `[label](url)` links and
/// `![alt](url)` images. That would hand the agent back the arbitrary-URL and
/// arbitrary-network surface v1 deliberately removed — an agent could emit a
/// tappable link to any host inside a plain `text` node, bypassing both the
/// action allowlist and the assetId-only image policy.
///
/// This renderer therefore supports **formatting only**. Link and image
/// syntax is reduced to its visible label; the URL is discarded and never
/// becomes tappable. Interactive UI stays where it belongs: structured
/// protocol nodes with allowlisted actions.
///
/// Supported: `#`/`##`/`###` headings, `-`/`*`/`+` bullets, `1.` ordered
/// lists, `**bold**`, `__bold__`, `*italic*`, `_italic_`, `` `code` ``,
/// blank-line paragraph breaks.
///
/// Everything else is passed through as literal text.
abstract final class AiUiMarkdown {
  /// Markers that make a string worth parsing. Plain prose short-circuits to
  /// a single `Text`, which keeps `maxLines` and ellipsis behaviour intact.
  static final RegExp _hasMarkup = RegExp(
    r'(\*\*|__|[*_`]|!?\[[^\]]*\]\([^)]*\)'
    r'|^\s{0,3}#{1,6}\s|^\s*[-*+]\s|^\s*\d+\.\s)',
    multiLine: true,
  );

  static bool looksLikeMarkdown(String text) => _hasMarkup.hasMatch(text);

  /// Builds the block-level widget for [text].
  ///
  /// Returns `null` when the text has no markup, so the caller can render its
  /// own plain `Text` and keep `maxLines`/overflow handling.
  static Widget? build(
    BuildContext context,
    String text, {
    required TextStyle baseStyle,
    TextAlign textAlign = TextAlign.start,
  }) {
    if (!looksLikeMarkdown(text)) return null;

    final blocks = _parseBlocks(context, text, baseStyle, textAlign);
    if (blocks.isEmpty) return null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.xs,
      children: blocks,
    );
  }

  static List<Widget> _parseBlocks(
    BuildContext context,
    String text,
    TextStyle baseStyle,
    TextAlign textAlign,
  ) {
    final typography = context.appTypography;
    final widgets = <Widget>[];
    final paragraph = <String>[];

    void flushParagraph() {
      if (paragraph.isEmpty) return;
      final joined = paragraph.join(' ').trim();
      paragraph.clear();
      if (joined.isEmpty) return;
      widgets.add(
        Text.rich(
          TextSpan(children: inlineSpans(context, joined, baseStyle)),
          textAlign: textAlign,
        ),
      );
    }

    for (final rawLine in text.split('\n')) {
      final line = rawLine.trimRight();
      final trimmed = line.trimLeft();

      if (trimmed.isEmpty) {
        flushParagraph();
        continue;
      }

      final heading = RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(trimmed);
      if (heading != null) {
        flushParagraph();
        final level = heading.group(1)!.length;
        final style = level <= 2
            ? typography.semiBold(typography.title3)
            : typography.semiBold(typography.regularNormal);
        widgets.add(
          Text.rich(
            TextSpan(
              children: inlineSpans(
                context,
                heading.group(2)!,
                style.copyWith(color: baseStyle.color),
              ),
            ),
            textAlign: textAlign,
          ),
        );
        continue;
      }

      final bullet = RegExp(r'^[-*+]\s+(.*)$').firstMatch(trimmed);
      if (bullet != null) {
        flushParagraph();
        widgets.add(
          _listRow(
            context,
            marker: '•',
            content: bullet.group(1)!,
            style: baseStyle,
          ),
        );
        continue;
      }

      final ordered = RegExp(r'^(\d+)\.\s+(.*)$').firstMatch(trimmed);
      if (ordered != null) {
        flushParagraph();
        widgets.add(
          _listRow(
            context,
            marker: '${ordered.group(1)}.',
            content: ordered.group(2)!,
            style: baseStyle,
          ),
        );
        continue;
      }

      paragraph.add(trimmed);
    }

    flushParagraph();
    return widgets;
  }

  /// A marker plus its content. `Row` is direction-aware, so the marker sits
  /// on the visual start in both English and Arabic with no extra work.
  static Widget _listRow(
    BuildContext context, {
    required String marker,
    required String content,
    required TextStyle style,
  }) => Padding(
    padding: EdgeInsetsDirectional.only(start: AppSpacing.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.sm,
      children: [
        Text(marker, style: style),
        Expanded(
          child: Text.rich(
            TextSpan(children: inlineSpans(context, content, style)),
          ),
        ),
      ],
    ),
  );

  /// Converts inline markup into spans.
  ///
  /// Deliberately produces no `recognizer` on any span: nothing here is ever
  /// tappable, so this cannot become a navigation or network surface.
  static List<InlineSpan> inlineSpans(
    BuildContext context,
    String input,
    TextStyle base,
  ) {
    final colors = context.appColors;
    final typography = context.appTypography;

    // Link and image syntax collapses to its visible label; the URL is
    // discarded. `![alt](url)` is handled before `[label](url)` so the
    // leading `!` does not survive.
    final text = input
        .replaceAllMapped(
          RegExp(r'!\[([^\]]*)\]\([^)]*\)'),
          (m) => m.group(1) ?? '',
        )
        .replaceAllMapped(
          RegExp(r'\[([^\]]*)\]\([^)]*\)'),
          (m) => m.group(1) ?? '',
        );

    final spans = <InlineSpan>[];
    final buffer = StringBuffer();

    void flush() {
      if (buffer.isEmpty) return;
      spans.add(TextSpan(text: buffer.toString(), style: base));
      buffer.clear();
    }

    var i = 0;
    while (i < text.length) {
      final rest = text.substring(i);

      final bold = RegExp(r'^(\*\*|__)(.+?)\1').firstMatch(rest);
      if (bold != null) {
        flush();
        spans.add(
          TextSpan(
            text: bold.group(2),
            style: typography.semiBold(base),
          ),
        );
        i += bold.group(0)!.length;
        continue;
      }

      final code = RegExp('^`([^`]+)`').firstMatch(rest);
      if (code != null) {
        flush();
        spans.add(
          TextSpan(
            text: code.group(1),
            style: base.copyWith(
              color: colors.textSecondary,
              fontFamilyFallback: const ['monospace'],
            ),
          ),
        );
        i += code.group(0)!.length;
        continue;
      }

      // Single `*`/`_` only counts as italic when it wraps non-space content,
      // so `a * b` and snake_case_words stay literal.
      final italic = RegExp(r'^([*_])(?!\s)(.+?)(?<!\s)\1').firstMatch(rest);
      if (italic != null) {
        flush();
        spans.add(
          TextSpan(
            text: italic.group(2),
            style: base.copyWith(fontStyle: FontStyle.italic),
          ),
        );
        i += italic.group(0)!.length;
        continue;
      }

      buffer.write(text[i]);
      i++;
    }

    flush();
    return spans;
  }
}
