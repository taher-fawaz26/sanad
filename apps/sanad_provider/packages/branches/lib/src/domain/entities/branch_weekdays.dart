/// The `branches` package's **canonical** all-caps weekday codes.
///
/// These are the single internal representation every consumer keys against —
/// the add-branch day picker, the working-hours editor, and the details
/// summary lookup. They are deliberately independent of the backend's casing.
///
/// The backend uses **Title-case** (`"Saturday"`) for branch availability day
/// codes in *both* directions — it returns Title-case on read and, despite an
/// earlier assumption to the contrary, also **requires** Title-case on write
/// (sending `"SATURDAY"` is rejected with `400 day must be one of the following
/// values: Monday, …`). The casing therefore lives only at the API boundary:
///  - read: [normalize] Title-case → canonical all-caps, applied once at
///    `BranchAvailabilityDto.toDomain`, so day-keyed lookups don't silently
///    miss and render every day "Closed" (SAN-780);
///  - write: [toApiDay] canonical all-caps → Title-case, applied once at
///    `BranchAvailabilityDto.entityToMap`, so the domain's casing never leaks
///    into the request body (SAN-780 write-path regression).
///
/// (The `service-provider/working-hours` company schedule is a *separate*
/// subsystem with its own Title-case `WorkingHoursDayIds` — it does not route
/// through here in either direction.)
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

  /// Normalizes a backend weekday code to this schema's canonical all-caps
  /// form (`"Saturday"` → `"SATURDAY"`).
  ///
  /// The backend returns Title-case day codes on read for *both* a branch's
  /// own custom `availability` and the company schedule, while every internal
  /// consumer keys against [all] (all-caps). An un-normalized Title-case code
  /// therefore falls through to "Closed" for every day even when hours exist
  /// (SAN-780). This is applied once, at the single deserialization boundary
  /// `BranchAvailabilityDto.toDomain`, so every `BranchAvailabilityEntity` the
  /// package produces — from either source — shares one casing convention.
  /// Uppercasing is locale-independent for these ASCII enum tokens and maps
  /// each Title-case day onto its [all] counterpart; an unrecognized code is
  /// returned uppercased unchanged.
  static String normalize(String day) => day.toUpperCase();

  /// Inverse of [normalize]: maps a canonical all-caps day to the backend's
  /// Title-case **write** spelling (`"SATURDAY"` → `"Saturday"`).
  ///
  /// The branch-availability write endpoints (`POST`/`PATCH /branches`) reject
  /// the all-caps code with `400 day must be one of the following values:
  /// Monday, …`, so the canonical domain value must be denormalized here at the
  /// serialization boundary (`BranchAvailabilityDto.entityToMap`). Exhaustive
  /// over the seven weekdays; input casing is irrelevant (it is normalized
  /// first), and an unrecognized code degrades to a generic Title-case rather
  /// than leaking an unexpected value.
  static String toApiDay(String day) => switch (day.toUpperCase()) {
    saturday => 'Saturday',
    sunday => 'Sunday',
    monday => 'Monday',
    tuesday => 'Tuesday',
    wednesday => 'Wednesday',
    thursday => 'Thursday',
    friday => 'Friday',
    _ => _titleCase(day),
  };

  static String _titleCase(String value) => value.isEmpty
      ? value
      : '${value[0].toUpperCase()}${value.substring(1).toLowerCase()}';
}
