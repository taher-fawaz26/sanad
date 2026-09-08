import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_client/src/ui/glass/client_glass_surface.dart';
import 'package:sanad_client/src/ui/glass/client_glass_tokens.dart';
import 'package:testing/testing.dart';

/// The client's glass primitive.
///
/// The assertions that matter here are the cost ones. A `BackdropFilter` is the
/// most expensive widget in this app's vocabulary and the two ways to misuse it
/// — nesting them, and blurring more of the screen than the surface draws — are
/// invisible until a device stutters, so they are pinned here rather than left
/// to a code review to notice.
void main() {
  Future<void> pumpGlass(
    WidgetTester tester,
    Widget child, {
    TextDirection direction = TextDirection.ltr,
  }) => pumpDsWidget(
    tester,
    Directionality(
      textDirection: direction,
      // Something to actually blur, so the filter has work to do rather than
      // sampling a flat colour.
      child: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF9F9FA), Color(0xFFC9FBD8)],
                ),
              ),
            ),
          ),
          Center(child: child),
        ],
      ),
    ),
  );

  group('the surface itself', () {
    testWidgets('it blurs exactly once', (tester) async {
      await pumpGlass(
        tester,
        ClientGlassSurface(
          borderRadius: BorderRadius.circular(16),
          child: const Text('readable'),
        ),
      );

      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(find.text('readable'), findsOneWidget);
    });

    testWidgets('the blur is clipped to the surface, never the screen', (
      tester,
    ) async {
      // A full-screen filter is the one pattern the performance budget rules
      // out, so the clip has to be an ancestor of the filter and not a sibling.
      await pumpGlass(
        tester,
        ClientGlassSurface(
          borderRadius: BorderRadius.circular(16),
          child: const SizedBox(width: 100, height: 40),
        ),
      );

      expect(
        find.ancestor(
          of: find.byType(BackdropFilter),
          matching: find.byType(ClipRRect),
        ),
        findsOneWidget,
      );
    });

    testWidgets('it is isolated from what scrolls behind it', (tester) async {
      await pumpGlass(
        tester,
        ClientGlassSurface(
          borderRadius: BorderRadius.circular(16),
          child: const SizedBox(width: 100, height: 40),
        ),
      );

      expect(
        find.ancestor(
          of: find.byType(BackdropFilter),
          matching: find.byType(RepaintBoundary),
        ),
        findsWidgets,
      );
    });

    testWidgets('padding is inside the glass', (tester) async {
      // So the padded area is blurred and tinted along with the rest. Padding
      // outside would leave a hard-edged gap between the tint and the content.
      await pumpGlass(
        tester,
        ClientGlassSurface(
          borderRadius: BorderRadius.circular(16),
          padding: const EdgeInsets.all(12),
          child: const Text('inset'),
        ),
      );

      expect(
        find.ancestor(
          of: find.text('inset'),
          matching: find.byType(BackdropFilter),
        ),
        findsOneWidget,
      );
    });

    testWidgets('content stays hit-testable through the glass', (
      tester,
    ) async {
      var taps = 0;
      await pumpGlass(
        tester,
        ClientGlassSurface(
          borderRadius: BorderRadius.circular(16),
          child: TextButton(
            onPressed: () => taps++,
            child: const Text('press'),
          ),
        ),
      );

      await tester.tap(find.text('press'));
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets('it lays out the same under RTL', (tester) async {
      await pumpGlass(
        tester,
        ClientGlassSurface(
          borderRadius: BorderRadius.circular(16),
          padding: const EdgeInsetsDirectional.only(start: 24),
          child: const Text('نص'),
        ),
        direction: TextDirection.rtl,
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(find.text('نص'), findsOneWidget);
    });
  });

  group('nesting is a build error, not a slow frame', () {
    testWidgets('a glass surface inside a glass surface trips the assert', (
      tester,
    ) async {
      await pumpGlass(
        tester,
        ClientGlassSurface(
          borderRadius: BorderRadius.circular(16),
          child: ClientGlassSurface(
            borderRadius: BorderRadius.circular(8),
            child: const Text('inner'),
          ),
        ),
      );

      final error = tester.takeException();
      expect(error, isAssertionError);
      expect(
        error.toString(),
        contains('Nested backdrop filters'),
      );
    });

    testWidgets('two side by side are fine', (tester) async {
      // Peers, not ancestors. The nav header draws exactly this shape — a
      // glass pill beside a glass button.
      await pumpGlass(
        tester,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClientGlassSurface(
              borderRadius: BorderRadius.circular(24),
              level: ClientGlassLevel.nav,
              child: const Text('one'),
            ),
            ClientGlassSurface(
              borderRadius: BorderRadius.circular(24),
              level: ClientGlassLevel.nav,
              child: const Text('two'),
            ),
          ],
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(BackdropFilter), findsNWidgets(2));
    });
  });

  group('the levels are a system, not free parameters', () {
    test('blur stays inside the budget at every level', () {
      for (final level in ClientGlassLevel.values) {
        final sigma = ClientGlassTokens.sigmaFor(level);
        expect(sigma, greaterThan(0));
        // Past roughly 24 a surface reads as opaque frosted plastic and stops
        // looking like glass, while costing strictly more to draw.
        expect(sigma, lessThanOrEqualTo(24));
      }
    });

    testWidgets('the surface a user reads is the most opaque', (tester) async {
      // The composer is the one glass panel someone reads a sentence off, so
      // it must let the least through.
      late Color navTint;
      late Color surfaceTint;
      late Color floatingTint;

      await pumpDsWidget(
        tester,
        Builder(
          builder: (context) {
            navTint = ClientGlassTokens.tintFor(
              context,
              ClientGlassLevel.nav,
            );
            surfaceTint = ClientGlassTokens.tintFor(
              context,
              ClientGlassLevel.surface,
            );
            floatingTint = ClientGlassTokens.tintFor(
              context,
              ClientGlassLevel.floating,
            );
            return const SizedBox();
          },
        ),
      );

      expect(surfaceTint.a, greaterThan(navTint.a));
      expect(navTint.a, greaterThan(floatingTint.a));
    });
  });
}
