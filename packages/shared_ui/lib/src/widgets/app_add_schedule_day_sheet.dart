import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// One selectable day option for [AppAddScheduleDaySheet].
class AppScheduleDayOption {
  const AppScheduleDayOption({
    required this.id,
    required this.label,
  });

  /// Stable id returned in [AppAddScheduleDayResult.day] (e.g. API code).
  final String id;

  /// Localized label shown in the day field and picker.
  final String label;
}

/// Opens a day picker for [AppAddScheduleDaySheet].
///
/// `shared_ui` cannot depend on `sheet_navigation` (lower dependency tier),
/// so the picker itself is injected — the caller opens whatever sheet it
/// likes (typically `SheetNavigator.push` with an `AppActionList`) and calls
/// [onDaySelected] when the user taps a row. Mirrors the side-effect style
/// used by every other action-list call site: the row's own tap handles
/// dismissal, [onDaySelected] just updates state.
typedef ScheduleDayPicker =
    void Function(
      BuildContext context,
      List<AppScheduleDayOption> days,
      AppScheduleDayOption selectedDay,
      ValueChanged<AppScheduleDayOption> onDaySelected,
    );

/// Result of a confirmed [AppAddScheduleDaySheet] submission.
class AppAddScheduleDayResult {
  const AppAddScheduleDayResult({
    required this.day,
    required this.from,
    required this.to,
  });

  /// Selected [AppScheduleDayOption.id].
  final String day;

  /// Start time in `HH:mm` (24-hour).
  final String from;

  /// End time in `HH:mm` (24-hour).
  final String to;
}

/// Figma `Views / Bottom Sheets` — Add custom day (`287:7918`).
///
/// Shell-agnostic schedule day form — pair with `SheetNavigator`, a modal
/// sheet, or any other container. On confirm, pops an
/// [AppAddScheduleDayResult]; dismiss without confirming pops `null`.
///
/// Example:
/// ```dart
/// final result = await SheetNavigator.push<AppAddScheduleDayResult>(
///   context,
///   AppAddScheduleDaySheet(
///     days: options,
///     dayLabel: 'Day'.tr(),
///     fromLabel: 'From'.tr(),
///     toLabel: 'To'.tr(),
///     confirmLabel: 'Add day'.tr(),
///     cancelLabel: 'Cancel'.tr(),
///     onPickDay: (context, days, selected, onDaySelected) {
///       SheetNavigator.push<void>(
///         context,
///         AppActionList(
///           items: days
///               .map((day) => AppActionSheetItem(
///                     label: day.label,
///                     onTap: () => onDaySelected(day),
///                   ))
///               .toList(),
///         ),
///         settings: SheetRouteSettings(title: 'Day'.tr(), padChild: false),
///       );
///     },
///   ),
///   settings: SheetRouteSettings(title: 'Add custom day'.tr()),
/// );
/// ```
class AppAddScheduleDaySheet extends StatefulWidget {
  AppAddScheduleDaySheet({
    required this.days,
    required this.dayLabel,
    required this.fromLabel,
    required this.toLabel,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.onPickDay,
    this.initialFrom = const TimeOfDay(hour: 10, minute: 0),
    this.initialTo = const TimeOfDay(hour: 14, minute: 0),
    super.key,
  }) : assert(days.isNotEmpty, 'days must not be empty');

  final List<AppScheduleDayOption> days;
  final String dayLabel;
  final String fromLabel;
  final String toLabel;
  final String confirmLabel;
  final String cancelLabel;
  final ScheduleDayPicker onPickDay;
  final TimeOfDay initialFrom;
  final TimeOfDay initialTo;

  @override
  State<AppAddScheduleDaySheet> createState() => _AppAddScheduleDaySheetState();
}

class _AppAddScheduleDaySheetState extends State<AppAddScheduleDaySheet> {
  late AppScheduleDayOption _selectedDay;
  late TimeOfDay _fromTime;
  late TimeOfDay _toTime;

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.days.first;
    _fromTime = widget.initialFrom;
    _toTime = widget.initialTo;
  }

  bool get _isValid {
    final fromMinutes = _fromTime.hour * 60 + _fromTime.minute;
    final toMinutes = _toTime.hour * 60 + _toTime.minute;
    return toMinutes > fromMinutes;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppSelectField(
          label: widget.dayLabel,
          value: _selectedDay.label,
          onTap: _pickDay,
        ),
        SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: AppSelectField(
                label: widget.fromLabel,
                value: localizations.formatTimeOfDay(_fromTime),
                showChevron: false,
                onTap: () => _pickTime(isFrom: true),
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppSelectField(
                label: widget.toLabel,
                value: localizations.formatTimeOfDay(_toTime),
                showChevron: false,
                onTap: () => _pickTime(isFrom: false),
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.xl),
        AppButton(
          label: widget.confirmLabel,
          onPressed: _isValid ? _submit : null,
        ),
      ],
    );
  }

  void _pickDay() {
    widget.onPickDay(context, widget.days, _selectedDay, (day) {
      setState(() => _selectedDay = day);
    });
  }

  Future<void> _pickTime({required bool isFrom}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isFrom ? _fromTime : _toTime,
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: context.appColors.primary,
              onPrimary: context.appColors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
      if (isFrom) {
        _fromTime = picked;
      } else {
        _toTime = picked;
      }
    });
  }

  void _submit() {
    Navigator.of(context).pop(
      AppAddScheduleDayResult(
        day: _selectedDay.id,
        from: _toApiTime(_fromTime),
        to: _toApiTime(_toTime),
      ),
    );
  }

  static String _toApiTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
