import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/src/rendering/ai_ui_strings.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Renders the protocol's *structured* values in the device locale.
///
/// This is the payoff for sending `{amount: 100, currency: "AED"}` and an
/// ISO-8601 UTC instant instead of pre-formatted prose: the agent never has to
/// know whether the reader sees `AED 100` or `١٠٠ د.إ`, or whether their clock
/// is 12- or 24-hour. It says what the value *is*; this file decides how it
/// looks, using the same `intl` conventions as the rest of the app.
abstract final class AiUiFormatters {
  static String money(BuildContext context, AiUiMoney money) {
    final locale = Localizations.localeOf(context).toString();
    // Whole amounts read better without trailing zeros in a chat bubble;
    // fractional amounts keep two digits so 99.5 does not become 100.
    final hasFraction = money.amount % 1 != 0;
    return NumberFormat.currency(
      locale: locale,
      name: money.currency,
      decimalDigits: hasFraction ? 2 : 0,
    ).format(money.amount);
  }

  /// Explicit `h:mm a` rather than `DateFormat.jm()`, because the skeleton
  /// form follows the *device* locale's clock preference and the product wants
  /// 12-hour with AM/PM in both languages (see
  /// `.claude/rules/localization.md`).
  static String dateTime(BuildContext context, DateTime utc) {
    final locale = Localizations.localeOf(context).toString();
    final local = utc.toLocal();
    final day = DateFormat('d MMM', locale).format(local);
    final time = DateFormat('h:mm a', locale).format(local);
    return '$day · $time';
  }

  static String distance(
    BuildContext context,
    num metres, {
    AiUiStrings strings = AiUiStrings.fallback,
  }) {
    final locale = Localizations.localeOf(context).toString();
    if (metres < 1000) {
      final value = NumberFormat.decimalPattern(locale).format(metres.round());
      return '$value ${strings.metresSuffix}';
    }
    final value = NumberFormat(
      '#,##0.#',
      locale,
    ).format(metres / 1000);
    return '$value ${strings.kilometresSuffix}';
  }

  static String rating(BuildContext context, double value) {
    final locale = Localizations.localeOf(context).toString();
    return NumberFormat('0.0', locale).format(value);
  }
}
