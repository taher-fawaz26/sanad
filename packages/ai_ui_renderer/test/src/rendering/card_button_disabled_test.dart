// Regression for A-07: a `time_slots` Confirm with no slot selected was
// already inert (`onTap: null`) and already reported `enabled: false` to
// accessibility — but it still painted the full accent, so it was
// pixel-identical to a live button. Tapping it did nothing, with no
// explanation, which is the most common "this app is broken" pattern there is.
//
// Semantics already reported `enabled: false` before the fix, so that is not
// what regressed and not what these assert; the paint is.
//
// The fix is purely visual, and these tests pin the visual: same widget, two
// materially different paints.

import 'package:ai_ui_renderer/ai_ui_renderer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testing/testing.dart';

Material _material(WidgetTester tester) => tester.widget<Material>(
  find.descendant(
    of: find.byType(AiCardButton),
    matching: find.byType(Material),
  ),
);

Text _label(WidgetTester tester) => tester.widget<Text>(
  find.descendant(
    of: find.byType(AiCardButton),
    matching: find.byType(Text),
  ),
);

Future<void> _pump(WidgetTester tester, {required bool enabled}) =>
    pumpDsWidget(
      tester,
      Scaffold(
        body: Center(
          child: AiCardButton(
            label: 'Confirm',
            onTap: enabled ? () {} : null,
          ),
        ),
      ),
    );

void main() {
  group('AiCardButton', () {
    testWidgets('a disabled button does not paint the accent', (tester) async {
      await _pump(tester, enabled: true);
      final enabledColor = _material(tester).color;
      final enabledLabel = _label(tester).style?.color;

      await _pump(tester, enabled: false);
      final disabledColor = _material(tester).color;
      final disabledLabel = _label(tester).style?.color;

      expect(
        disabledColor,
        isNot(enabledColor),
        reason: 'a disabled Confirm must not look like a live one',
      );
      expect(disabledLabel, isNot(enabledLabel));
    });

    testWidgets('an enabled button still fires', (tester) async {
      var taps = 0;
      await pumpDsWidget(
        tester,
        Scaffold(
          body: Center(
            child: AiCardButton(label: 'Confirm', onTap: () => taps++),
          ),
        ),
      );

      await tester.tap(find.byType(AiCardButton));
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets('a disabled button does not fire', (tester) async {
      await _pump(tester, enabled: false);

      await tester.tap(find.byType(AiCardButton));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
