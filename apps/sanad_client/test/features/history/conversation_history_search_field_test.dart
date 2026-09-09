import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_client/src/features/history/src/presentation/conversation_history_tokens.dart';
import 'package:sanad_client/src/features/history/src/presentation/widgets/conversation_history_search_field.dart';
import 'package:testing/testing.dart';

/// The search box is the shared [AppSearchField] carrying Figma's own spec
/// through a scoped `Theme`.
///
/// That indirection is the reason this test exists: if the override stopped
/// being applied, the field would keep working and quietly render the shared
/// 40dp / 8dp bar every other screen uses — a silent visual regression no
/// behavioural test would notice.
void main() {
  late TextEditingController controller;

  setUp(() => controller = TextEditingController());
  tearDown(() => controller.dispose());

  Future<void> pumpField(
    WidgetTester tester, {
    TextDirection direction = TextDirection.ltr,
    ValueChanged<String>? onChanged,
  }) => pumpDsWidget(
    tester,
    Directionality(
      textDirection: direction,
      child: Scaffold(
        body: Center(
          child: ConversationHistorySearchField(
            controller: controller,
            onChanged: onChanged ?? (_) {},
          ),
        ),
      ),
    ),
  );

  testWidgets('it is the shared search field, not a second one', (
    tester,
  ) async {
    await pumpField(tester);

    expect(find.byType(AppSearchField), findsOneWidget);
  });

  testWidgets('it carries Figma height, radius and glyph size', (tester) async {
    await pumpField(tester);

    final field = tester.widget<AppSearchField>(find.byType(AppSearchField));
    // The bordered variant is what gives Figma's white fill and hairline.
    expect(field.variant, AppSearchFieldVariant.bordered);
    // Figma has no trailing control on this field.
    expect(field.showMicIcon, isFalse);

    expect(
      tester.getSize(find.byType(AppSearchField)).height,
      moreOrLessEquals(
        responsiveDimension(ConversationHistoryTokens.searchHeight),
        epsilon: 0.5,
      ),
      reason: 'Figma 52dp, where the shared spec resolves 40dp',
    );

    final decorated = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byType(AppSearchField),
        matching: find.byType(AnimatedContainer),
      ),
    );
    final decoration = decorated.decoration! as BoxDecoration;
    expect(
      decoration.borderRadius,
      BorderRadius.circular(
        responsiveDimension(ConversationHistoryTokens.searchRadius),
      ),
      reason: 'Figma 16dp, where the shared spec resolves 8dp',
    );
    expect(decoration.border, isNotNull, reason: 'Figma draws a hairline');

    final glyph = tester.widget<SvgPicture>(
      find.descendant(
        of: find.byType(AppSearchField),
        matching: find.byType(SvgPicture),
      ),
    );
    expect(
      glyph.width,
      moreOrLessEquals(
        responsiveDimension(ConversationHistoryTokens.searchIconSize),
        epsilon: 0.5,
      ),
      reason: 'Figma 20dp, where the bordered variant resolves 22dp',
    );
    expect(
      (glyph.bytesLoader as SvgAssetLoader).assetName,
      AppSvgs.search,
      reason: 'the shared search glyph, not a new export',
    );
  });

  testWidgets('typing reports the query', (tester) async {
    final queries = <String>[];
    await pumpField(tester, onChanged: queries.add);

    await tester.enterText(find.byType(TextField), 'flight');
    await tester.pump();

    expect(queries.last, 'flight');
    expect(controller.text, 'flight');
  });

  testWidgets('it lays out mirrored without overflowing', (tester) async {
    await pumpField(tester, direction: TextDirection.rtl);

    expect(tester.takeException(), isNull);
    // The glyph leads the text in both directions — the row is directional,
    // so RTL puts it at the visual right without a second layout.
    final glyphCentre = tester
        .getCenter(
          find.descendant(
            of: find.byType(AppSearchField),
            matching: find.byType(SvgPicture),
          ),
        )
        .dx;
    final fieldCentre = tester.getCenter(find.byType(AppSearchField)).dx;
    expect(glyphCentre, greaterThan(fieldCentre));
  });
}
