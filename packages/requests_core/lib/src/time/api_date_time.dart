/// Date/time codec for the request-lifecycle endpoints.
///
/// The backend is explicit about this and it is easy to get wrong:
///
/// > Preferred start, as an ISO 8601 instant. Send an explicit offset — a naive
/// > local string is interpreted as UTC and lands four hours out.
///
/// `DateTime.toIso8601String()` only emits an offset when the value is already
/// UTC; on a local `DateTime` it produces `2026-09-12T10:00:00.000` with no
/// zone at all, which is exactly the four-hours-out bug in Gulf Standard Time.
/// [encode] therefore normalises to UTC first, so the wire value always carries
/// a `Z`.
abstract final class ApiDateTime {
  ApiDateTime._();

  /// Serializes [value] as an ISO 8601 instant with an explicit `Z` offset.
  static String encode(DateTime value) => value.toUtc().toIso8601String();

  /// Serializes [value], or `null` when it is `null`.
  static String? encodeNullable(DateTime? value) =>
      value == null ? null : encode(value);

  /// Parses a wire instant into local time, or `null` when absent or malformed.
  ///
  /// Returns `null` rather than throwing: a single unparseable timestamp must
  /// degrade one field, not fail the whole response.
  static DateTime? decode(Object? raw) {
    if (raw is! String || raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }
}
