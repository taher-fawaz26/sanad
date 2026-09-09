import 'package:core/core.dart';
import 'package:easy_localization/easy_localization.dart';

/// Formats a conversation's timestamp as Figma's card caption — "Today ·
/// 2:30 PM", "Yesterday · 3:45 PM", "12 Aug · 5:20 PM".
///
/// Mirrors the provider app's `ActivityLogTimeFormatter`: one `{day} · {time}`
/// key with the day word localized separately, so the separator and the order
/// of the two halves are a translator's decision rather than string
/// concatenation in Dart.
///
/// The `locale` argument must be an `intl`-style tag (`en_US`, `ar`) — pass
/// the active app locale from the call site
/// (`Localizations.localeOf(context).toString()`).
abstract final class ConversationHistoryTimeFormatter {
  ConversationHistoryTimeFormatter._();

  /// The caption Figma draws.
  static String format(DateTime timestamp, {required String locale}) =>
      'history.day_time'.tr(
        namedArgs: {
          'day': dayLabel(timestamp, locale: locale),
          'time': timeLabel(timestamp, locale: locale),
        },
      );

  /// The caption's first half: a relative day word where there is one, and a
  /// day-and-month otherwise.
  ///
  /// Figma's fifth card reads "Tomorrow · 9:00 AM". A conversation dated in
  /// the future is a quirk of the mock rather than a state the backend will
  /// produce — but handling the day word instead of letting it fall through
  /// to a bare date is what makes the screen render the design as drawn.
  ///
  /// Public alongside [format] because this is where the branching lives: the
  /// choice of day word is the one decision here worth asserting on its own,
  /// and it is not observable through [format]'s interpolated result.
  static String dayLabel(DateTime timestamp, {required String locale}) {
    final local = timestamp.toLocal();

    return switch (local) {
      final value when value.isToday => 'history.today'.tr(),
      final value when value.isYesterday => 'history.yesterday'.tr(),
      final value when value.isTomorrow => 'history.tomorrow'.tr(),
      _ => DateFormat('d MMM', locale).format(local),
    };
  }

  /// The caption's second half.
  ///
  /// An **explicit** `h:mm a` pattern rather than `DateFormat.jm()`, whose
  /// skeleton follows the device locale and can resolve to a 24-hour clock on
  /// a device the design never anticipated (see
  /// `.claude/rules/localization.md`).
  static String timeLabel(DateTime timestamp, {required String locale}) =>
      DateFormat('h:mm a', locale).format(timestamp.toLocal());
}
