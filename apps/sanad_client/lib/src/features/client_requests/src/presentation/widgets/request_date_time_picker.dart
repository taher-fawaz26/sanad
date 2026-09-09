import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Picks a date and then a time, returning the combined instant.
///
/// Two steps rather than one control because the design system ships a themed
/// date picker but no combined one, and the backend wants a single instant.
///
/// Returns `null` if either step is dismissed.
Future<DateTime?> pickRequestDateTime(
  BuildContext context, {
  DateTime? initial,
}) async {
  final now = DateTime.now();
  // A request is always for the future, so the calendar starts today. The
  // server rejects a past `preferredAt` with a 400 regardless.
  final seed = (initial != null && initial.isAfter(now)) ? initial : now;

  final date = await showAppDatePicker(
    context: context,
    initialDate: seed,
    firstDate: DateTime(now.year, now.month, now.day),
    lastDate: DateTime(now.year + 2, now.month, now.day),
  );
  if (date == null || !context.mounted) return null;

  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(seed),
  );
  if (time == null) return null;

  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}

/// Formats an instant for display in the user's locale.
///
/// Locale-aware on purpose: under an Arabic locale this renders Arabic month
/// names and ص/م rather than falling back to en_US.
String formatRequestDateTime(BuildContext context, DateTime value) =>
    DateFormat.yMMMd(context.locale.toString()).add_jm().format(value);

/// Formats a time-only value for the alternative-window chips.
String formatRequestTime(BuildContext context, DateTime value) =>
    DateFormat.jm(context.locale.toString()).format(value);
