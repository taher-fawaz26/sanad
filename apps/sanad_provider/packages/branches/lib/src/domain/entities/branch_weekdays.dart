/// Exact backend weekday codes for branch availability payloads
/// (`WorkingHoursDayDto.day`, branch flavor — all-caps, unlike the Title-case
/// codes the provider-wide `service-provider/working-hours` endpoint uses).
abstract final class BranchWeekdays {
  BranchWeekdays._();

  static const String saturday = 'SATURDAY';
  static const String sunday = 'SUNDAY';
  static const String monday = 'MONDAY';
  static const String tuesday = 'TUESDAY';
  static const String wednesday = 'WEDNESDAY';
  static const String thursday = 'THURSDAY';
  static const String friday = 'FRIDAY';

  /// Week order starting Saturday.
  static const all = <String>[
    saturday,
    sunday,
    monday,
    tuesday,
    wednesday,
    thursday,
    friday,
  ];
}
