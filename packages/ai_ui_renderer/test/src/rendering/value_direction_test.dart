// Regression for R-02: under Arabic, a time slot labelled "10:30 AM" rendered
// as "AM 10:30". The meridiem is a run of Latin letters, and the card's RTL
// base direction pushed it to the visual start of the value.
//
// The guard has to be conditional. A label the agent already localized carries
// its own strong RTL characters, and forcing an LTR base on that would reorder
// its words — trading one bidi bug for another.

import 'package:ai_ui_renderer/ai_ui_renderer.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiUiFormatters.valueDirection', () {
    test('forces LTR for a 12-hour time', () {
      expect(AiUiFormatters.valueDirection('10:30 AM'), TextDirection.ltr);
      expect(AiUiFormatters.valueDirection('2:00 PM'), TextDirection.ltr);
    });

    test('forces LTR for a 24-hour time and a bare number', () {
      expect(AiUiFormatters.valueDirection('14:00'), TextDirection.ltr);
      expect(AiUiFormatters.valueDirection('42'), TextDirection.ltr);
    });

    test('forces LTR for a reference or plate', () {
      expect(AiUiFormatters.valueDirection('REF-2024-4821'), TextDirection.ltr);
      expect(AiUiFormatters.valueDirection('A-48219'), TextDirection.ltr);
    });

    test('inherits for an Arabic label the agent localized', () {
      // Must be null, not ltr: an LTR base would reorder the words.
      expect(AiUiFormatters.valueDirection('صباحاً'), isNull);
      expect(AiUiFormatters.valueDirection('العاشرة والنصف صباحًا'), isNull);
    });

    test('inherits for a predominantly Arabic mixed label', () {
      expect(AiUiFormatters.valueDirection('الموعد ١٠:٣٠ صباحًا'), isNull);
    });

    test('an empty label inherits rather than being forced', () {
      expect(AiUiFormatters.valueDirection(''), TextDirection.ltr);
    });
  });
}
