import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Picks a date and then a time, returning the combined instant.
///
/// The same two-step shape as the client composer: the design system ships a
/// themed date picker but no combined control, and the backend wants one
/// instant.
Future<DateTime?> pickProviderDateTime(
  BuildContext context, {
  DateTime? initial,
}) async {
  final now = DateTime.now();
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

/// Formats an instant in the viewer's locale.
///
/// Locale-aware so an Arabic locale renders Arabic month names and ص/م rather
/// than falling back to en_US.
String formatProviderDateTime(BuildContext context, DateTime value) =>
    DateFormat.yMMMd(context.locale.toString()).add_jm().format(value);
