/// Date-based validators — pure Dart.
abstract final class DateValidators {
  DateValidators._();

  static const int registrationMinAgeYears = 16;

  static DateTime latestBirthDateForMinAge({
    int minYears = registrationMinAgeYears,
    DateTime? reference,
  }) {
    final ref = reference ?? DateTime.now();
    return DateTime(ref.year - minYears, ref.month, ref.day);
  }

  static bool isOldEnough(
    DateTime? birthDate, {
    int minYears = registrationMinAgeYears,
  }) {
    if (birthDate == null) return false;
    final cutoff = latestBirthDateForMinAge(minYears: minYears);
    return !birthDate.isAfter(cutoff);
  }

  static bool isNotExpired(DateTime? expiryDate, {DateTime? reference}) {
    if (expiryDate == null) return false;
    final ref = reference ?? DateTime.now();
    return !expiryDate.isBefore(ref);
  }
}
