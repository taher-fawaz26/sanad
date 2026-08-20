import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:branches/src/domain/entities/branch_time_slot_entity.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// API weekday codes used in branch availability payloads.
abstract final class BranchWeekdays {
  BranchWeekdays._();

  static const all = <String>[
    'SATURDAY',
    'SUNDAY',
    'MONDAY',
    'TUESDAY',
    'WEDNESDAY',
    'THURSDAY',
    'FRIDAY',
  ];
}

/// Formats 24-hour API times for schedule UI.
abstract final class BranchScheduleFormatter {
  BranchScheduleFormatter._();

  static String formatTime(String time24) {
    final time = _parseTime(time24);
    if (time == null) return time24;
    // Explicit `h:mm a` pattern (not `DateFormat.jm()`) so the display is
    // always 12-hour with a locale-appropriate AM/PM marker (AM/PM in en,
    // ص/م in ar). `DateFormat.jm()` resolves via the current Intl locale,
    // which on many device configurations picks a 24-hour skeleton — that
    // mismatched the time picker (which is 12-hour) and produced strings
    // like "14:00 – 10:00" on the read-only working-hours list (SAN-568).
    return DateFormat('h:mm a').format(
      DateTime(2000, 1, 1, time.hour, time.minute),
    );
  }

  static String formatSlot(BranchTimeSlotEntity slot) =>
      '${formatTime(slot.from)} – ${formatTime(slot.to)}';

  static String formatAvailability(BranchAvailabilityEntity availability) {
    if (availability.slots.isEmpty) return '';
    return availability.slots.map(formatSlot).join(', ');
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
