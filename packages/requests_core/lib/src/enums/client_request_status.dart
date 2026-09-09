/// The lifecycle of a client service request, as owned by the server.
///
/// The nine named values are exactly the backend contract — no client-invented
/// states. [unknown] is deliberately **not** a lifecycle state: it is the parse
/// sentinel for a value this build has never heard of, so a server that adds a
/// status in a later release degrades one row instead of crashing a whole list.
/// It has no [apiValue] and must never be sent to the API.
///
/// Transitions are **not** driven only by user action. The backend moves
/// requests on timers — `SUBMITTED → EXPIRED`, `SCHEDULED → IN_PROGRESS`,
/// `AWAITING_CONFIRMATION → COMPLETED` — so a client must re-read the server
/// state rather than predicting it locally.
///
/// Named [ClientRequestStatus], not `RequestStatus`: `package:core` already
/// exports a `RequestStatus` for async call lifecycle
/// (`initial`/`loading`/`success`/`failure`), and the two are routinely in
/// scope together in a bloc.
enum ClientRequestStatus {
  draft('DRAFT'),
  submitted('SUBMITTED'),
  scheduled('SCHEDULED'),
  inProgress('IN_PROGRESS'),
  awaitingConfirmation('AWAITING_CONFIRMATION'),
  disputed('DISPUTED'),
  completed('COMPLETED'),
  cancelled('CANCELLED'),
  expired('EXPIRED'),

  /// Parse sentinel for an unrecognised server value. Never serialized.
  unknown(null)
  ;

  const ClientRequestStatus(this._apiValue);

  final String? _apiValue;

  /// The wire value. Throws for [unknown], which must never be sent.
  String get apiValue =>
      _apiValue ??
      (throw StateError('ClientRequestStatus.unknown has no API value'));

  /// Parses a wire value, falling back to [unknown] for anything unrecognised
  /// (including `null`).
  static ClientRequestStatus fromApi(String? raw) {
    if (raw == null) return ClientRequestStatus.unknown;
    for (final value in ClientRequestStatus.values) {
      if (value._apiValue == raw) return value;
    }
    return ClientRequestStatus.unknown;
  }

  /// Whether the request has reached a terminal state — no further client or
  /// provider action can move it.
  bool get isClosed =>
      this == completed || this == cancelled || this == expired;

  /// Whether the request is still a draft the client may freely edit.
  bool get isDraft => this == draft;
}
