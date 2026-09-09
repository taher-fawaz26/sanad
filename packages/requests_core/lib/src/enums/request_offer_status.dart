/// The state of a single offer node inside a negotiation thread.
///
/// A thread holds at most one [pending] offer; whose turn it is comes from that
/// offer's actor, not from this enum. The distinction that matters most in copy
/// is [lost] versus [rejected]: **lost** means another provider won and this
/// one was never personally judged, while **rejected** means the client
/// explicitly declined this offer. [superseded] is what a countered offer
/// becomes — it was answered, not refused.
///
/// [unknown] is a parse sentinel, not a server state. See
/// `ClientRequestStatus.unknown`.
enum RequestOfferStatus {
  pending('PENDING'),
  accepted('ACCEPTED'),
  rejected('REJECTED'),
  superseded('SUPERSEDED'),
  lost('LOST'),
  withdrawn('WITHDRAWN'),
  voided('VOIDED'),
  expired('EXPIRED'),

  /// Parse sentinel for an unrecognised server value. Never serialized.
  unknown(null)
  ;

  const RequestOfferStatus(this._apiValue);

  final String? _apiValue;

  String get apiValue =>
      _apiValue ??
      (throw StateError('RequestOfferStatus.unknown has no API value'));

  static RequestOfferStatus fromApi(String? raw) {
    if (raw == null) return RequestOfferStatus.unknown;
    for (final value in RequestOfferStatus.values) {
      if (value._apiValue == raw) return value;
    }
    return RequestOfferStatus.unknown;
  }

  /// Whether this offer is the thread's open node, awaiting a reply.
  bool get isPending => this == pending;
}
