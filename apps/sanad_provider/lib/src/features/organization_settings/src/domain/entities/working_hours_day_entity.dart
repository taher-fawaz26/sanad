import 'package:equatable/equatable.dart';

/// Exact backend weekday enum values for
/// `service-provider/working-hours` (`WorkingHoursDayDto.day`).
///
/// These are Title-case (`"Monday"`), NOT the all-caps `"MONDAY"` codes used
/// by the unrelated branch-availability schema in the `branches` package —
/// do not reuse `BranchWeekdays` here, the two APIs disagree on casing.
abstract final class WorkingHoursDayIds {
  WorkingHoursDayIds._();

  static const String saturday = 'Saturday';
  static const String sunday = 'Sunday';
  static const String monday = 'Monday';
  static const String tuesday = 'Tuesday';
  static const String wednesday = 'Wednesday';
  static const String thursday = 'Thursday';
  static const String friday = 'Friday';

  /// Week order starting Saturday, matching the rest of the app's
  /// day-of-week presentation (see `BranchWeekdays.all`).
  static const List<String> all = [
    saturday,
    sunday,
    monday,
    tuesday,
    wednesday,
    thursday,
    friday,
  ];
}

/// One working-hours time slot — `WorkingHoursSlotDto`.
class WorkingHoursSlotEntity extends Equatable {
  const WorkingHoursSlotEntity({required this.from, required this.to});

  /// `HH:MM`, 24-hour.
  final String from;

  /// `HH:MM`, 24-hour. Must be later than [from].
  final String to;

  @override
  List<Object?> get props => [from, to];
}

/// One working day's schedule — `WorkingHoursDayDto`.
class WorkingHoursDayEntity extends Equatable {
  const WorkingHoursDayEntity({required this.day, required this.slots});

  /// One of [WorkingHoursDayIds] — exact backend spelling.
  final String day;
  final List<WorkingHoursSlotEntity> slots;

  @override
  List<Object?> get props => [day, slots];
}
