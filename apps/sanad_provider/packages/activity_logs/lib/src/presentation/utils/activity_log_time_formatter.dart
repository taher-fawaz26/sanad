import 'package:core/core.dart';
import 'package:easy_localization/easy_localization.dart';

/// Formats an activity-log entry's `timestamp` as "Today, 2:30 PM",
/// "Yesterday, 4:45 PM", or "Aug 15, 2025, 5:20 PM" — mirroring
/// `BranchScheduleFormatter`'s explicit-pattern approach (never
/// `DateFormat.jm()`, which can resolve to 24-hour on some device locales).
abstract final class ActivityLogTimeFormatter {
  ActivityLogTimeFormatter._();

  /// [locale] must be an `intl`-style tag (e.g. `en_US`, `ar`) — pass the
  /// active app locale from the call site (`context.locale.toString()`).
  static String format(DateTime timestamp, {required String locale}) {
    final local = timestamp.toLocal();
    final time = DateFormat('h:mm a', locale).format(local);

    if (local.isToday) {
      return 'activity_log.day_time'.tr(
        namedArgs: {'day': 'activity_log.today'.tr(), 'time': time},
      );
    }
    if (local.isYesterday) {
      return 'activity_log.day_time'.tr(
        namedArgs: {'day': 'activity_log.yesterday'.tr(), 'time': time},
      );
    }
    final date = DateFormat('d MMM y', locale).format(local);
    return 'activity_log.day_time'.tr(namedArgs: {'day': date, 'time': time});
  }
}
