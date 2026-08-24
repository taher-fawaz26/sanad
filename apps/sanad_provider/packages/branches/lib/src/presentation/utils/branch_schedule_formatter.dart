import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:branches/src/domain/entities/branch_time_slot_entity.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

export 'package:branches/src/domain/entities/branch_weekdays.dart';

/// Formats 24-hour API times for schedule UI.
abstract final class BranchScheduleFormatter {
  BranchScheduleFormatter._();

  /// Formats a `HH:mm` API time as `h:mm a` in the given [locale].
  ///
  /// Explicit `h:mm a` pattern (not `DateFormat.jm()`) so the display is
  /// always 12-hour with a locale-appropriate AM/PM marker (`AM/PM` in en,
  /// `ص/م` in ar). `DateFormat.jm()` resolves via the current Intl locale
  /// skeleton, which on many device configurations picks 24-hour and
  /// produced strings like `14:00 – 10:00` on the read-only working-hours
  /// list (SAN-568).
  ///
  /// [locale] must be an `intl`-style tag (e.g. `en_US`, `ar`). Pass the
  /// active app locale from the call site (`context.locale.toString()`) —
  /// there is no reliable ambient value in tests or before EasyLocalization
  /// bootstraps, and omitting it silently reverts to English `AM/PM`
  /// regardless of app language (SAN-573 root cause of "AM/PM shown in
  /// English on the main list").
  static String formatTime(String time24, {String? locale}) {
    final time = _parseTime(time24);
    if (time == null) return time24;
    return DateFormat('h:mm a', locale).format(
      DateTime(2000, 1, 1, time.hour, time.minute),
    );
  }

  static String formatSlot(BranchTimeSlotEntity slot, {String? locale}) =>
      '${formatTime(slot.from, locale: locale)} – '
      '${formatTime(slot.to, locale: locale)}';

  static String formatAvailability(
    BranchAvailabilityEntity availability, {
    String? locale,
  }) {
    if (availability.slots.isEmpty) return '';
    return availability.slots
        .map((slot) => formatSlot(slot, locale: locale))
        .join(', ');
  }

  static String toApiTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static TimeOfDay parseApiTime(String time24) {
    final parsed = _parseTime(time24);
    return parsed ?? const TimeOfDay(hour: 9, minute: 0);
  }

  static String localizedDay(String dayCode) {
    final key = 'branches.add_branch.days.${dayCode.toLowerCase()}';
    return key.tr();
  }

  static List<BranchAvailabilityEntity> copyAvailability(
    List<BranchAvailabilityEntity> source,
  ) => source
      .map(
        (entry) => BranchAvailabilityEntity(
          day: entry.day,
          slots: entry.slots
              .map(
                (slot) => BranchTimeSlotEntity(
                  from: slot.from,
                  to: slot.to,
                ),
              )
              .toList(),
        ),
      )
      .toList();

  static TimeOfDay? _parseTime(String time24) {
    final parts = time24.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }
}
