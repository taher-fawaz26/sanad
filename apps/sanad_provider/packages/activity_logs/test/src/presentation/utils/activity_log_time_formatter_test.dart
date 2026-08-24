import 'package:activity_logs/src/presentation/utils/activity_log_time_formatter.dart';
import 'package:easy_localization/easy_localization.dart' show DateFormat;
// Not part of the public API — needed only to seed `.tr()` synchronously for
// this test (see `setUpAll` below).
// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// Same reason as above — needed to construct the seed data for `.load`.
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // `.tr()` resolves through the plain `Localization.instance` singleton
  // when called with no `BuildContext` (see `easy_localization`'s top-level
  // `tr()`), so seeding it directly here exercises the real
  // "{day}, {time}" interpolation without mounting an `EasyLocalization`
  // widget — unlike a full widget-tree bootstrap, this is synchronous and
  // touches no `SharedPreferences`, so it doesn't hit the hang other tests
  // in this codebase avoid by skipping EasyLocalization entirely.
  setUpAll(() {
    Localization.load(
      const Locale('en'),
      translations: Translations({
        'activity_log': {
          'today': 'Today',
          'yesterday': 'Yesterday',
          'day_time': '{day}, {time}',
        },
      }),
    );
  });

  group('ActivityLogTimeFormatter.format', () {
    test('today renders "Today, <time>"', () {
      final now = DateTime.now();
      final timestamp = DateTime(now.year, now.month, now.day, 14, 30);

      final result = ActivityLogTimeFormatter.format(
        timestamp,
        locale: 'en_US',
      );

      expect(result, 'Today, 2:30 PM');
    });

    test('yesterday renders "Yesterday, <time>"', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final timestamp = DateTime(
        yesterday.year,
        yesterday.month,
        yesterday.day,
        16,
        45,
      );

      final result = ActivityLogTimeFormatter.format(
        timestamp,
        locale: 'en_US',
      );

      expect(result, 'Yesterday, 4:45 PM');
    });

    test('an older date renders "<d MMM y>, <time>"', () {
      final timestamp = DateTime(2025, 8, 15, 17, 20);

      final result = ActivityLogTimeFormatter.format(
        timestamp,
        locale: 'en_US',
      );

      final expectedDate = DateFormat('d MMM y', 'en_US').format(timestamp);
      expect(result, '$expectedDate, 5:20 PM');
    });
  });
}
