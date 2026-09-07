import 'package:ai_ui_renderer/ai_ui_renderer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/renderer_test_support.dart';

/// Every visible character of the rendered subtree, in order.
String _renderedText(WidgetTester tester) {
  final buffer = StringBuffer();
  for (final widget in tester.allWidgets) {
    if (widget is RichText) buffer.write(widget.text.toPlainText());
  }
  return buffer.toString();
}

Iterable<TextSpan> _spans(WidgetTester tester) sync* {
  Iterable<TextSpan> walk(InlineSpan span) sync* {
    if (span is! TextSpan) return;
    yield span;
    for (final child in span.children ?? const <InlineSpan>[]) {
      yield* walk(child);
    }
  }

  for (final widget in tester.allWidgets) {
    if (widget is RichText) yield* walk(widget.text);
  }
}

void main() {
  group('markdown in text nodes', () {
    testWidgets('renders bold without showing the asterisks', (tester) async {
      await pumpNodes(tester, [
        {'type': 'text', 'id': 't', 'text': 'I found **3 services** nearby.'},
      ]);

      expect(_renderedText(tester), contains('I found 3 services nearby.'));
      expect(_renderedText(tester), isNot(contains('**')));

      final bold = _spans(
        tester,
      ).firstWhere((s) => s.text == '3 services');
      expect(bold.style?.fontWeight, isNot(FontWeight.w400));
    });

    testWidgets('renders italic and inline code', (tester) async {
      await pumpNodes(tester, [
        {'type': 'text', 'id': 't', 'text': 'Use _care_ with `svc_123`.'},
      ]);

      final text = _renderedText(tester);
      expect(text, contains('Use care with svc_123.'));
      expect(text, isNot(contains('`')));

      final italic = _spans(tester).firstWhere((s) => s.text == 'care');
      expect(italic.style?.fontStyle, FontStyle.italic);
    });

    testWidgets('renders headings without the hashes', (tester) async {
      await pumpNodes(tester, [
        {'type': 'text', 'id': 't', 'text': '### Your appointment\nTomorrow.'},
      ]);

      final text = _renderedText(tester);
      expect(text, contains('Your appointment'));
      expect(text, contains('Tomorrow.'));
      expect(text, isNot(contains('#')));
    });

    testWidgets('renders bullet and ordered lists', (tester) async {
      await pumpNodes(tester, [
        {
          'type': 'text',
          'id': 't',
          'text': '- AC repair\n- Plumbing\n\n1. Pick a service\n2. Book it',
        },
      ]);

      final text = _renderedText(tester);
      expect(text, contains('AC repair'));
      expect(text, contains('Plumbing'));
      expect(text, contains('•'));
      expect(text, contains('Pick a service'));
      expect(text, contains('1.'));
    });

    testWidgets('markdown link syntax renders the label, never the url', (
      tester,
    ) async {
      await pumpNodes(tester, [
        {
          'type': 'text',
          'id': 't',
          'text': 'See [our branches](https://evil.example/steal).',
        },
      ]);

      final text = _renderedText(tester);
      expect(text, contains('See our branches.'));
      expect(text, isNot(contains('evil.example')));

      // The whole point: a link in prose cannot become a tap target, so the
      // agent gains no navigation surface it does not have through actions.
      for (final span in _spans(tester)) {
        expect(span.recognizer, isNull);
      }
    });

    testWidgets('markdown image syntax renders no image', (tester) async {
      await pumpNodes(tester, [
        {
          'type': 'text',
          'id': 't',
          'text': 'Look: ![a photo](https://evil.example/x.png)',
        },
      ]);

      expect(find.byType(Image), findsNothing);
      expect(_renderedText(tester), isNot(contains('evil.example')));
    });

    testWidgets('plain prose keeps the simple Text path with maxLines', (
      tester,
    ) async {
      await pumpNodes(tester, [
        {
          'type': 'text',
          'id': 't',
          'text': 'No markup at all here.',
          'maxLines': 1,
        },
      ]);

      final widget = tester.widget<Text>(find.text('No markup at all here.'));
      expect(widget.maxLines, 1);
      expect(widget.overflow, TextOverflow.ellipsis);
    });

    testWidgets('an ltrValue is never parsed as markdown', (tester) async {
      await pumpNodes(tester, [
        {
          'type': 'text',
          'id': 't',
          'text': 'svc_*_123',
          'direction': 'ltrValue',
        },
      ]);

      // The value survives character-for-character (inside the LTR isolate),
      // because a reference id is data, not prose.
      expect(
        _renderedText(tester) +
            tester
                .widgetList<Text>(find.byType(Text))
                .map(
                  (
                    w,
                  ) => w.data ?? '',
                )
                .join(),
        contains('svc_*_123'),
      );
    });
  });

  group('AiUiMarkdown.looksLikeMarkdown', () {
    test('is false for ordinary prose', () {
      expect(
        AiUiMarkdown.looksLikeMarkdown('I found three services near you.'),
        isFalse,
      );
    });

    test('is true for the markers the agent actually emits', () {
      for (final sample in <String>[
        '**bold**',
        '### heading',
        '- bullet',
        '1. first',
        'a `code` span',
      ]) {
        expect(AiUiMarkdown.looksLikeMarkdown(sample), isTrue, reason: sample);
      }
    });
  });
}
