import 'package:design_system/design_system.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      builder: (_, _) => MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: Center(child: child)),
      ),
    ),
  );
}

void main() {
  group('AppInlineLinkText', () {
    testWidgets('renders the leading text and the link text as one row', (
      tester,
    ) async {
      await _pump(
        tester,
        AppInlineLinkText(
          text: "Didn't find your service? ",
          linkText: 'Request New service',
          onLinkTap: () {},
        ),
      );

      final richText = tester.widget<Text>(find.byType(Text));
      final span = richText.textSpan! as TextSpan;
      expect(span.children, hasLength(2));
      expect(
        (span.children![0] as TextSpan).text,
        "Didn't find your service? ",
      );
      expect((span.children![1] as TextSpan).text, 'Request New service');
    });

    testWidgets('only the link span is tappable', (tester) async {
      var tapped = false;
      await _pump(
        tester,
        AppInlineLinkText(
          text: "Didn't find your service? ",
          linkText: 'Request New service',
          onLinkTap: () => tapped = true,
        ),
      );

      final richText = tester.widget<Text>(find.byType(Text));
      final span = richText.textSpan! as TextSpan;
      final leading = span.children![0] as TextSpan;
      final link = span.children![1] as TextSpan;

      expect(leading.recognizer, isNull);
      expect(link.recognizer, isA<TapGestureRecognizer>());

      (link.recognizer! as TapGestureRecognizer).onTap!();
      expect(tapped, isTrue);
    });
  });
}
