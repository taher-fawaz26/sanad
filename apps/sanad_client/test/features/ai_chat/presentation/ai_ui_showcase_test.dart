import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/ai_ui_renderer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_client/src/features/ai_chat/src/ai_chat_config.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/showcase_fixtures.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/actions/ai_chat_action_handlers.dart';
import 'package:testing/testing.dart';

/// The cheap regression net over the whole semantic catalog.
///
/// Every showcase fixture is raw wire JSON, so this drives the same three
/// pieces a live payload does — `AiChatConfig.validator`, the default renderer
/// registry, and `AiUiSurface` — and asserts two things per fixture: the app's
/// own validator accepts it without a complaint, and it draws in both text
/// directions without throwing.
///
/// That combination is what stops the showcase from becoming decoration. A
/// component whose fixture stops validating (a renamed field, a tightened
/// limit, an action dropped from the allowlist) fails here rather than
/// appearing as an empty space in a screenshot nobody re-took.
///
/// The one group excluded from the zero-diagnostics rule is the degradation
/// fixture, which exists *because* it is rejected in part — it gets its own
/// assertion below.
void main() {
  /// The document a fixture produces, plus whatever the validator objected to.
  ({AiUiDocument? document, List<AiUiDiagnostic> diagnostics}) run(
    ShowcaseFixture fixture,
  ) {
    // keepUnsupportedNodes mirrors the page, which passes `!kReleaseMode`: the
    // degradation fixture's unknown types must survive as markers.
    final result = AiChatConfig.validator(
      keepUnsupportedNodes: true,
    ).validate(fixture.payload);
    return (document: result.document, diagnostics: result.diagnostics);
  }

  /// Renders [document] through the real host at [direction].
  Future<void> pumpDocument(
    WidgetTester tester,
    AiUiDocument document,
    TextDirection direction,
  ) async {
    await pumpDsWidget(
      tester,
      AiUiHost(
        environment: AiUiEnvironment(
          registry: defaultRendererRegistry(showUnsupportedMarker: true),
          actions: buildAiChatActionRegistry(onSendMessage: (_) {}),
        ),
        child: Directionality(
          textDirection: direction,
          child: Scaffold(
            body: SingleChildScrollView(
              child: AiUiSurface(document: document),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  final groups = showcaseGroups();

  test('the showcase covers every semantic type in the catalog', () {
    // The guard that makes "add a component, add a fixture" enforced rather
    // than remembered. Primitives are covered by the renderer package's own
    // tests; what a designer reviews here is the semantic set.
    final rendered = {
      for (final section in groups)
        for (final fixture in section.fixtures)
          for (final block in fixture.blocks) block['type'],
    };
    final semantic = AiUiNodeType.values.where((type) => type.isSemantic);

    expect(
      semantic.where((type) => !rendered.contains(type.wire)),
      isEmpty,
      reason: 'every semantic type needs a showcase fixture',
    );
  });

  for (final section in groups) {
    group(section.title, () {
      for (final fixture in section.fixtures) {
        test('${fixture.title} validates', () {
          final result = run(fixture);

          expect(result.document, isNotNull);
          expect(result.document!.blocks, isNotEmpty);
          // Every fixture but the ones that declare themselves degrading must
          // validate silently. `degrades` is a property of the fixture, so a
          // new deliberately-broken example cannot quietly excuse a real
          // regression somewhere else.
          if (!fixture.degrades) {
            expect(
              result.diagnostics.map((d) => '${d.code.wire} @ ${d.path}'),
              isEmpty,
            );
          }
        });

        testWidgets('${fixture.title} renders in both directions', (
          tester,
        ) async {
          final document = run(fixture).document!;

          for (final direction in TextDirection.values) {
            await pumpDocument(tester, document, direction);
            expect(tester.takeException(), isNull);
          }
        });
      }
    });
  }

  group('degradation fixture', () {
    late ShowcaseFixture fixture;

    setUp(() {
      fixture = groups
          .expand((section) => section.fixtures)
          .firstWhere((f) => f.title == 'Degradation');
    });

    test('drops the unknown types and keeps the rest', () {
      final result = run(fixture);

      // Three blocks in, three out: one unknown type replaced by its
      // fallbackText, one kept as a debug marker, and the known node after
      // them untouched. That last one is the whole point — a component this
      // build has never heard of must not cost the payload behind it.
      expect(result.document!.blocks, hasLength(3));
      expect(
        result.document!.blocks.last,
        isA<AiUiTextNode>().having(
          (node) => node.text,
          'text',
          'The rest of the payload still renders.',
        ),
      );
      expect(
        result.diagnostics.map((d) => d.code),
        contains(AiUiDiagnosticCode.unknownNodeType),
      );
    });

    testWidgets('shows the fallback text and a debug marker', (tester) async {
      await pumpDocument(
        tester,
        run(fixture).document!,
        TextDirection.ltr,
      );

      expect(
        find.text(
          'A component this build does not know, rendered as its '
          'fallback text.',
        ),
        findsOne,
      );
      // The marker names the type the agent asked for, which is what makes a
      // catalog mismatch debuggable. It is debug-only by construction: the
      // page passes `!kReleaseMode`.
      expect(find.textContaining('holographic_map'), findsOne);
      expect(kReleaseMode, isFalse);
    });
  });
}
