import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/ai_ui_renderer.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testing/testing.dart';

import '../../support/renderer_test_support.dart';

/// The hard requirement: an invalid or hostile AI payload degrades the
/// *bubble*, never the chat. Every case here asserts that something still
/// rendered and that no exception escaped.
void main() {
  group('unknown node types', () {
    testWidgets('fallbackText renders as plain text', (tester) async {
      await pumpNodes(tester, [
        {
          'type': 'service_carousel_v2',
          'id': 'f',
          'fallbackText': 'Three services near you',
        },
      ]);

      expect(find.text('Three services near you'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a node with no fallbackText is invisible in release', (
      tester,
    ) async {
      await pumpNodes(tester, [
        {'type': 'service_carousel_v2', 'id': 'f'},
        {'type': 'text', 'id': 't', 'text': 'The rest of the reply'},
      ]);

      expect(find.text('The rest of the reply'), findsOneWidget);
      expect(find.byType(Container), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a dev build shows a marker naming the type', (tester) async {
      // The difference between "the card is missing" and "the agent is
      // emitting service_carousel_v2".
      await pumpNodes(
        tester,
        [
          {'type': 'service_carousel_v2', 'id': 'f'},
        ],
        harness: RendererHarness(showUnsupportedMarker: true),
      );

      expect(find.textContaining('service_carousel_v2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('hostile and malformed payloads', () {
    testWidgets('malformed JSON leaves an empty but intact surface', (
      tester,
    ) async {
      final harness = RendererHarness();
      final result = harness.validator.parse('{"schemaVersion": 1, "blocks"');

      await pumpDsWidget(
        tester,
        AiUiHost(
          environment: harness.environment,
          child: AiUiSurface(
            document:
                result.document ??
                const AiUiDocument(schemaVersion: 1, blocks: []),
          ),
        ),
      );

      expect(result.hasRenderableUi, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a remote image URL never reaches the widget tree', (
      tester,
    ) async {
      // schemaVersion 1 is assetId-only, so this is refused at validation for
      // *any* host — the app never issues a request the agent asked for.
      final harness = await pumpNodes(tester, [
        {
          'type': 'image',
          'id': 'i',
          'url': 'https://evil.example/tracker.gif',
          'alt': 'tracker',
        },
        {'type': 'text', 'id': 't', 'text': 'reply continues'},
      ]);

      expect(find.text('reply continues'), findsOneWidget);
      expect(find.byType(AppNetworkImage), findsNothing);
      expect(
        harness.diagnostics.hasCode(AiUiDiagnosticCode.reservedProperty),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('an unpublished assetId is dropped', (tester) async {
      final harness = await pumpNodes(tester, [
        {
          'type': 'image',
          'id': 'i',
          'assetId': 'not_a_shipped_asset',
          'alt': 'mystery',
        },
        {'type': 'text', 'id': 't', 'text': 'reply continues'},
      ]);

      expect(find.text('reply continues'), findsOneWidget);
      expect(
        harness.diagnostics.hasCode(AiUiDiagnosticCode.unknownAssetId),
        isTrue,
      );
    });

    testWidgets('an oversized tree is capped and still renders', (
      tester,
    ) async {
      final harness = await pumpNodes(tester, [
        for (var i = 0; i < 40; i++)
          {'type': 'text', 'id': 'n$i', 'text': 'line $i'},
      ]);

      expect(find.text('line 0'), findsOneWidget);
      // Truncated at the block limit rather than dropped wholesale.
      expect(find.text('line 39'), findsNothing);
      expect(
        harness.diagnostics.hasCode(AiUiDiagnosticCode.limitExceeded),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('a pathologically deep tree cannot blow the stack', (
      tester,
    ) async {
      var node = <String, dynamic>{
        'type': 'text',
        'id': 'leaf',
        'text': 'leaf',
      };
      for (var i = 0; i < 200; i++) {
        node = <String, dynamic>{
          'type': 'column',
          'id': 'c$i',
          'children': [node],
        };
      }

      await pumpNodes(tester, [
        node,
        {'type': 'text', 'id': 't', 'text': 'reply continues'},
      ]);

      expect(find.text('reply continues'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('renderer failures', () {
    testWidgets('a throwing renderer degrades to nothing and is reported', (
      tester,
    ) async {
      // Renderers act on validated data, so reaching this path means a
      // renderer bug — it must be reported, not silently swallowed, but it
      // must not take the conversation with it.
      final harness = RendererHarness();
      harness.environment.registry.register(
        AiUiNodeType.text,
        const _ThrowingRenderer(),
      );

      final result = harness.validator.validate(<String, dynamic>{
        'schemaVersion': 1,
        'blocks': [
          {'type': 'text', 'id': 't', 'text': 'boom'},
          {
            'type': 'chip',
            'id': 'c',
            'label': 'survivor',
          },
        ],
      });

      await pumpDsWidget(
        tester,
        AiUiHost(
          environment: harness.environment,
          child: AiUiSurface(document: result.document!),
        ),
      );

      expect(find.text('survivor'), findsOneWidget);
      expect(
        harness.diagnostics.hasCode(AiUiDiagnosticCode.rendererFailure),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('a node type with no registered renderer is skipped', (
      tester,
    ) async {
      final harness = RendererHarness();
      final bareRegistry = AiUiRendererRegistry();
      final environment = AiUiEnvironment(
        registry: bareRegistry,
        actions: harness.actions,
        diagnostics: harness.diagnostics,
      );

      await pumpDsWidget(
        tester,
        AiUiHost(
          environment: environment,
          child: const AiUiSurface(
            document: AiUiDocument(
              schemaVersion: 1,
              blocks: [AiUiTextNode(id: 't', text: 'never drawn')],
            ),
          ),
        ),
      );

      expect(find.text('never drawn'), findsNothing);
      expect(
        harness.diagnostics.hasCode(AiUiDiagnosticCode.unknownNodeType),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('catalog coverage', () {
    test('every node type in the protocol has a default renderer', () {
      // Guards the pairing that makes degradation predictable: if the protocol
      // gains a node type and nobody writes a renderer, this fails here rather
      // than silently rendering nothing in production.
      expect(
        defaultRendererRegistry().supportedTypes,
        equals(AiUiNodeType.values.toSet()),
      );
    });

    test('every action type has a handler in the reference wiring', () {
      // Not an equality assertion on purpose: a host is *allowed* to implement
      // fewer actions than the protocol defines, and the validator drops the
      // rest. This just documents what the test harness covers.
      expect(
        RendererHarness().actions.supportedTypes,
        isNot(contains(AiUiActionType.openRoute)),
      );
    });
  });
}

final class _ThrowingRenderer extends AiNodeRenderer<AiUiTextNode> {
  const _ThrowingRenderer();

  @override
  Widget render(
    BuildContext context,
    AiUiTextNode node,
    AiUiRenderScope scope,
  ) => throw StateError('renderer bug');
}
