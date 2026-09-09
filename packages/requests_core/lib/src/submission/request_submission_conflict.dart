import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:requests_core/src/time/api_date_time.dart';

/// Why `POST /requests/:id/submit` answered `409`.
///
/// The draft itself was valid; the transition to a live request could not
/// complete under current market conditions. Each code implies a *different*
/// next user action, which is the whole reason this is typed rather than
/// collapsed into one error string.
enum RequestSubmissionConflictCode {
  /// No provider offers the selected service → suggest a different service.
  noProvidersForService('NO_PROVIDERS_FOR_SERVICE'),

  /// Providers exist but none serve this address → suggest a different address.
  noCoverage('NO_COVERAGE'),

  /// Providers cover the address but are closed then → offer [
  /// RequestSubmissionConflict.alternatives] as one-tap retry windows.
  outsideHours('OUTSIDE_HOURS'),

  /// A 409 that is not one of the matching codes — most often "already
  /// submitted". Falls back to the generic conflict message.
  unknown(null)
  ;

  const RequestSubmissionConflictCode(this._apiValue);

  final String? _apiValue;

  static RequestSubmissionConflictCode fromApi(String? raw) {
    if (raw == null) return RequestSubmissionConflictCode.unknown;
    final normalized = raw.trim().toUpperCase();
    for (final value in RequestSubmissionConflictCode.values) {
      if (value._apiValue == normalized) return value;
    }
    return RequestSubmissionConflictCode.unknown;
  }
}

/// A time window that *would* have matched, offered as a one-tap retry.
///
/// Only populated for [RequestSubmissionConflictCode.outsideHours]; the other
/// codes carry an empty list.
class RequestSubmissionAlternative extends Equatable {
  const RequestSubmissionAlternative({required this.start, this.end});

  /// Parses one entry defensively.
  ///
  /// The OpenAPI spec documents neither the 409 body nor this item's shape, so
  /// several plausible key spellings are accepted and a bare ISO string is
  /// treated as a start-only window. Returns `null` when nothing usable is
  /// present — an unreadable alternative is dropped, never rendered as a
  /// broken chip.
  static RequestSubmissionAlternative? tryParse(Object? raw) {
    if (raw is String) {
      final start = ApiDateTime.decode(raw);
      return start == null ? null : RequestSubmissionAlternative(start: start);
    }
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final start = _first(map, const ['start', 'from', 'startsAt', 'startAt']);
    if (start == null) return null;
    return RequestSubmissionAlternative(
      start: start,
      end: _first(map, const ['end', 'to', 'endsAt', 'endAt']),
    );
  }

  static DateTime? _first(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final parsed = ApiDateTime.decode(map[key]);
      if (parsed != null) return parsed;
    }
    return null;
  }

  final DateTime start;
  final DateTime? end;

  @override
  List<Object?> get props => [start, end];
}

/// A typed view of the structured submission conflict.
///
/// `ErrorMapper` already preserves the whole 409 body in
/// [Failure.metadata] — this reads it rather than re-parsing the response, so
/// nothing in the transport layer had to change to support code-specific UX.
class RequestSubmissionConflict extends Equatable {
  const RequestSubmissionConflict({
    required this.code,
    required this.alternatives,
    required this.message,
  });

  /// Reads a submission conflict out of [failure], or returns `null` when this
  /// is not a 409 at all.
  ///
  /// A 409 with an unrecognised code still produces a value (with
  /// [RequestSubmissionConflictCode.unknown]) so callers have one branch for
  /// "the server refused the transition" and can fall back to
  /// `failure.localizedMessage()` for the copy.
  static RequestSubmissionConflict? tryParse(Failure failure) {
    if (failure is! ConflictFailure) return null;
    final raw = failure.metadata?['alternatives'];
    final alternatives = raw is List
        ? raw
              .map(RequestSubmissionAlternative.tryParse)
              .nonNulls
              .toList(growable: false)
        : const <RequestSubmissionAlternative>[];
    return RequestSubmissionConflict(
      code: RequestSubmissionConflictCode.fromApi(failure.backendCode),
      alternatives: alternatives,
      message: failure.message,
    );
  }

  final RequestSubmissionConflictCode code;

  /// Retry windows. Empty for every code except
  /// [RequestSubmissionConflictCode.outsideHours], and possibly empty even
  /// there if the server sent none.
  final List<RequestSubmissionAlternative> alternatives;

  /// The server's own prose, kept so the UI can fall back to it for
  /// [RequestSubmissionConflictCode.unknown].
  final String message;

  /// Whether there are windows worth rendering as one-tap retries.
  bool get hasAlternatives => alternatives.isNotEmpty;

  @override
  List<Object?> get props => [code, alternatives, message];
}
