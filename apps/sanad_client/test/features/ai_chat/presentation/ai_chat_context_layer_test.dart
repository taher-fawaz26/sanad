import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/context/ai_chat_context_controller.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/context/ai_chat_context_layer.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/context/ai_chat_layout.dart';
import 'package:testing/testing.dart';

/// The context layer's contract, which is entirely about **presentation**:
/// where it sits, how it moves, and that it never covers or displaces the
/// composer. What it contains is somebody else's problem — these tests hand it
/// a plain box, because the layer must work the same whatever it is given.
void main() {
  const bodyKey = Key('context-body');
  const composerKey = Key('composer');
  const conversationKey = Key('conversation');

  Widget page({
    bool hasContext = true,
    AiChatContextController? controller,
    ValueChanged<AiChatContextExtent>? onExtentChanged,
  }) => AiChatLayout(
    conversation: const ColoredBox(
      key: conversationKey,
      color: Color(0xFFEEEEEE),
      child: SizedBox.expand(),
    ),
    context: hasContext
        ? AiChatContextLayer(
            controller: controller,
            peekLabel: 'You have 8 new offers',
            onExtentChanged: onExtentChanged,
            child: const SizedBox(key: bodyKey, height: 400),
          )
        : null,
    composer: const SizedBox(key: composerKey, height: 80),
  );

  group('availability', () {
    testWidgets('with nothing to offer the layer is not in the tree', (
      tester,
    ) async {
      await pumpDsWidget(tester, page(hasContext: false));

      expect(find.byType(AiChatContextLayer), findsNothing);
      expect(find.byKey(AiChatContextLayer.headerKey), findsNothing);
      // The chat looks exactly as it does without context: conversation and
      // composer, nothing between them.
      expect(find.byKey(conversationKey), findsOne);
      expect(find.byKey(composerKey), findsOne);
    });

    testWidgets('with content it shows the agent summary and the invitation', (
      tester,
    ) async {
      await pumpDsWidget(tester, page());

      expect(
        find.textContaining('You have 8 new offers'),
        findsOne,
        reason: 'the peek label is agent prose, rendered verbatim',
      );
      expect(find.textContaining('ai_chat.context_swipe_up'), findsOne);
    });
  });

  group('layer order', () {
    testWidgets('it sits above the conversation and below the composer', (
      tester,
    ) async {
      await pumpDsWidget(tester, page());

      final conversation = tester.getRect(find.byKey(conversationKey));
      final composer = tester.getRect(find.byKey(composerKey));
      final header = tester.getRect(find.byKey(AiChatContextLayer.headerKey));

      // Between the two, geometrically: the strip is inside the conversation's
      // box and finishes where the composer starts.
      expect(header.top, greaterThan(conversation.top));
      expect(header.bottom, lessThanOrEqualTo(composer.top + 1));
    });

    testWidgets('the composer stays hit-testable at every extent', (
      tester,
    ) async {
      var taps = 0;
      final controller = AiChatContextController();
      addTearDown(controller.dispose);

      await pumpDsWidget(
        tester,
        AiChatLayout(
          conversation: const SizedBox.expand(),
          context: AiChatContextLayer(
            controller: controller,
            peekLabel: 'You have 8 new offers',
            child: const SizedBox(height: 400),
          ),
          composer: GestureDetector(
            key: composerKey,
            onTap: () => taps++,
            child: const ColoredBox(
              color: Color(0xFFFFFFFF),
              child: SizedBox(height: 80, width: double.infinity),
            ),
          ),
        ),
      );

      final closedRect = tester.getRect(find.byKey(composerKey));
      await tester.tap(find.byKey(composerKey));

      controller.expand();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(composerKey));
      expect(taps, 2, reason: 'the layer must never swallow a composer tap');
      // And it did not move to get there.
      expect(tester.getRect(find.byKey(composerKey)), closedRect);
    });
  });

  group('dragging', () {
    testWidgets('up expands, down collapses', (tester) async {
      final settled = <AiChatContextExtent>[];
      await pumpDsWidget(tester, page(onExtentChanged: settled.add));

      final closedHeight = tester
          .getRect(find.byType(AiChatContextLayer))
          .height;
      final header = find.byKey(AiChatContextLayer.headerKey);

      await tester.drag(header, const Offset(0, -400));
      await tester.pumpAndSettle();

      final openHeight = tester.getSize(find.byKey(bodyKey)).height;
      expect(settled.last, AiChatContextExtent.expanded);
      expect(openHeight, greaterThan(0));

      await tester.drag(header, const Offset(0, 400));
      await tester.pumpAndSettle();

      expect(settled.last, AiChatContextExtent.peek);
      expect(
        tester.getRect(find.byType(AiChatContextLayer)).height,
        closedHeight,
      );
    });

    testWidgets('a short drag that is released early falls back', (
      tester,
    ) async {
      final settled = <AiChatContextExtent>[];
      await pumpDsWidget(tester, page(onExtentChanged: settled.add));

      // Under the snap threshold and slow enough not to read as a flick.
      await tester.timedDrag(
        find.byKey(AiChatContextLayer.headerKey),
        const Offset(0, -30),
        const Duration(milliseconds: 400),
      );
      await tester.pumpAndSettle();

      expect(settled, isNot(contains(AiChatContextExtent.expanded)));
    });

    testWidgets('a flick wins over position', (tester) async {
      final settled = <AiChatContextExtent>[];
      await pumpDsWidget(tester, page(onExtentChanged: settled.add));

      // Short travel, high velocity: someone who throws it upward meant to
      // open it even though they let go early.
      await tester.fling(
        find.byKey(AiChatContextLayer.headerKey),
        const Offset(0, -120),
        1500,
      );
      await tester.pumpAndSettle();

      expect(settled.last, AiChatContextExtent.expanded);
    });
  });

  group('the controller is a request channel, not a source of content', () {
    testWidgets('expand and collapse move the layer', (tester) async {
      final controller = AiChatContextController();
      addTearDown(controller.dispose);
      final settled = <AiChatContextExtent>[];

      await pumpDsWidget(
        tester,
        page(controller: controller, onExtentChanged: settled.add),
      );

      controller.expand();
      await tester.pumpAndSettle();
      expect(settled.last, AiChatContextExtent.expanded);

      controller.collapse();
      await tester.pumpAndSettle();
      expect(settled.last, AiChatContextExtent.peek);
    });

    testWidgets('it cannot conjure a layer that has no content', (
      tester,
    ) async {
      final controller = AiChatContextController();
      addTearDown(controller.dispose);

      await pumpDsWidget(
        tester,
        page(hasContext: false, controller: controller),
      );
      controller.expand();
      await tester.pumpAndSettle();

      expect(find.byType(AiChatContextLayer), findsNothing);
    });
  });

  testWidgets('reduced motion arrives at once rather than not at all', (
    tester,
  ) async {
    final controller = AiChatContextController();
    addTearDown(controller.dispose);
    final settled = <AiChatContextExtent>[];

    await pumpDsWidget(
      tester,
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: page(controller: controller, onExtentChanged: settled.add),
      ),
    );

    controller.expand();
    // One pump, no settle: with animations disabled the layer must already be
    // open, not merely on its way.
    await tester.pump();

    expect(tester.getSize(find.byKey(bodyKey)).height, greaterThan(0));
    expect(settled.last, AiChatContextExtent.expanded);
  });
}
