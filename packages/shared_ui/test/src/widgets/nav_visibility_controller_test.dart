import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

/// Pumps a real, attached `ListView` so [NavVisibilityController] has a live
/// `ScrollPosition` to read `maxScrollExtent`/`pixels` from. Visibility
/// changes are driven deterministically via `ScrollController.jumpTo`, which
/// notifies listeners synchronously with an exact pixel delta — no gesture
/// simulation / fling velocity involved.
Future<void> _pumpList(
  WidgetTester tester, {
  required ScrollController controller,
  required int itemCount,
  double itemExtent = 80,
  double viewportHeight = 600,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: viewportHeight,
          child: ListView.builder(
            controller: controller,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: itemCount,
            itemBuilder: (_, i) => SizedBox(height: itemExtent),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('NavVisibilityController', () {
    late NavVisibilityController controller;
    late ScrollController scrollController;

    // Defaults: scrollThreshold=24, minScrollExtentThreshold=40 — asserted
    // against explicitly below via the jump values chosen in each test.
    setUp(() {
      controller = NavVisibilityController();
      scrollController = ScrollController();
      controller.attach(scrollController);
    });

    tearDown(() {
      controller.dispose();
      scrollController.dispose();
    });

    testWidgets('starts visible', (tester) async {
      expect(controller.visible, isTrue);
    });

    testWidgets(
      '0 items: content has no scroll extent, stays visible',
      (tester) async {
        await _pumpList(tester, controller: scrollController, itemCount: 0);

        expect(scrollController.position.maxScrollExtent, 0);
        expect(controller.visible, isTrue);
      },
    );

    testWidgets(
      '3 items that fit entirely on screen: stays visible, cannot be '
      'hidden by any scroll attempt',
      (tester) async {
        await _pumpList(
          tester,
          controller: scrollController,
          itemCount: 3,
          itemExtent: 40,
        );

        expect(scrollController.position.maxScrollExtent, 0);
        scrollController.jumpTo(0);
        expect(controller.visible, isTrue);
      },
    );

    testWidgets(
      'content whose maxScrollExtent is below the threshold never hides, '
      'even on a jump larger than scrollThreshold',
      (tester) async {
        // 7 * 90 = 630 in a 600 viewport => maxScrollExtent = 30, below the
        // 40px "non-scrollable" gate.
        await _pumpList(
          tester,
          controller: scrollController,
          itemCount: 7,
          itemExtent: 90,
        );
        expect(scrollController.position.maxScrollExtent, 30);

        scrollController.jumpTo(30);
        expect(controller.visible, isTrue);
      },
    );

    testWidgets(
      'long list: scrolling down past the threshold hides; scrolling back '
      'up past the threshold shows',
      (tester) async {
        await _pumpList(
          tester,
          controller: scrollController,
          itemCount: 50,
        );
        expect(scrollController.position.maxScrollExtent, greaterThan(1000));

        scrollController.jumpTo(200);
        expect(controller.visible, isFalse);

        scrollController.jumpTo(100);
        expect(controller.visible, isTrue);
      },
    );

    testWidgets(
      'returning to the top always shows, regardless of how it hid',
      (tester) async {
        await _pumpList(
          tester,
          controller: scrollController,
          itemCount: 50,
        );

        scrollController.jumpTo(500);
        expect(controller.visible, isFalse);

        scrollController.jumpTo(0);
        expect(controller.visible, isTrue);
      },
    );

    testWidgets(
      'overscroll past the top (pull-to-refresh) never hides — the bar '
      'stays visible while refresh can start',
      (tester) async {
        await _pumpList(
          tester,
          controller: scrollController,
          itemCount: 50,
        );
        expect(controller.visible, isTrue);

        // A pull-to-refresh drag manifests as negative pixels (bounce past
        // the top edge).
        scrollController.jumpTo(-60);
        expect(controller.visible, isTrue);
      },
    );

    testWidgets(
      'overscroll past the bottom leaves visibility unchanged (not a real '
      'scroll intent)',
      (tester) async {
        await _pumpList(
          tester,
          controller: scrollController,
          itemCount: 50,
        );
        final maxExtent = scrollController.position.maxScrollExtent;

        scrollController.jumpTo(maxExtent + 80);
        expect(controller.visible, isTrue);
      },
    );

    testWidgets(
      'a single small jump below scrollThreshold does not hide',
      (tester) async {
        await _pumpList(
          tester,
          controller: scrollController,
          itemCount: 50,
        );

        scrollController.jumpTo(10);
        expect(controller.visible, isTrue);
      },
    );

    testWidgets(
      'several small same-direction jumps accumulate past the threshold '
      'and eventually hide',
      (tester) async {
        await _pumpList(
          tester,
          controller: scrollController,
          itemCount: 50,
        );

        scrollController.jumpTo(10); // accumulated 10
        expect(controller.visible, isTrue);
        scrollController.jumpTo(20); // accumulated 20
        expect(controller.visible, isTrue);
        scrollController.jumpTo(35); // accumulated 35 >= 24 threshold
        expect(controller.visible, isFalse);
      },
    );

    testWidgets(
      'show()/hide() are available for callers that need to force state '
      'directly',
      (tester) async {
        controller.hide();
        expect(controller.visible, isFalse);
        controller.show();
        expect(controller.visible, isTrue);
      },
    );
  });
}
