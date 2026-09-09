import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_client/src/features/history/src/presentation/conversation_history_time_formatter.dart';

/// The card's timestamp caption.
///
/// Asserted through `dayLabel`/`timeLabel` rather than the composed `format`,
/// because `format` interpolates through a localization key — and with no
/// `EasyLocalization` ancestor a missing key resolves to the key itself,
/// swallowing the arguments. The two halves are where the decisions are.
void main() {
  const locale = 'en_US';

  String dayOf(DateTime at) =>
      ConversationHistoryTimeFormatter.dayLabel(at, locale: locale);
  String timeOf(DateTime at) =>
      ConversationHistoryTimeFormatter.timeLabel(at, locale: locale);

  group('the day word', () {
    test('is Today for a timestamp from today', () {
      final now = DateTime.now();

      expect(
        dayOf(DateTime(now.year, now.month, now.day, 14, 30)),
        'history.today',
      );
    });

    test('is Yesterday for a timestamp from yesterday', () {
      expect(
        dayOf(DateTime.now().subtract(const Duration(days: 1))),
        'history.yesterday',
      );
    });

    test('is Tomorrow for a timestamp dated ahead', () {
      // Figma's fifth card. A future timestamp is a mock quirk, but it must
      // not fall through to a bare date and silently redraw the design.
      expect(
        dayOf(DateTime.now().add(const Duration(days: 1))),
        'history.tomorrow',
      );
    });

    test('falls back to a day and month for anything older', () {
      expect(dayOf(DateTime(2026, 8, 12, 17, 20)), '12 Aug');
    });
  });

  group('the time', () {
    test('is 12-hour with an AM/PM marker, never 24-hour', () {
      // `DateFormat.jm()`'s skeleton follows the device locale and can
      // resolve to a 24-hour clock; the explicit `h:mm a` pattern cannot.
      expect(timeOf(DateTime(2026, 9, 8, 9)), '9:00 AM');
      expect(timeOf(DateTime(2026, 9, 8, 15, 45)), '3:45 PM');
      expect(timeOf(DateTime(2026, 9, 8, 14, 30)), '2:30 PM');
    });
  });

  test('the composed caption carries both halves through one key', () {
    // Unlocalized, `tr` returns the key — which is itself the assertion that
    // the caption is built from a translator-owned template rather than
    // concatenated in Dart.
    expect(
      ConversationHistoryTimeFormatter.format(
        DateTime(2026, 9, 8, 14, 30),
        locale: locale,
      ),
      'history.day_time',
    );
  });
}
