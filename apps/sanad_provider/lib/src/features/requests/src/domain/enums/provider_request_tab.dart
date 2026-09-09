/// Which workspace tab a request sits in.
///
/// **Server-derived, and treated as canonical.** The backend computes it from
/// the request status *and* this provider's own offer thread, which the client
/// cannot reproduce: a SUBMITTED request is `NEW` to a provider that has not
/// bid, `AWAITING_CLIENT` to one that has, and `YOUR_TURN` to one the client
/// has countered. Re-deriving it locally would also break the per-tab counts,
/// because a paginated feed cannot be filtered after the fact.
enum ProviderRequestTab {
  /// Matched to one of your branches, and you have not offered yet.
  newRequest('NEW'),

  /// You have offered; the client has not replied.
  awaitingClient('AWAITING_CLIENT'),

  /// The client countered. The next move is yours.
  yourTurn('YOUR_TURN'),

  /// Booked, not started.
  scheduled('SCHEDULED'),

  /// Under way.
  inProgress('IN_PROGRESS'),

  /// You marked it finished; the client has not confirmed.
  toConfirm('TO_CONFIRM'),

  /// Completed, cancelled, expired, or lost to another provider.
  closed('CLOSED'),

  /// Parse sentinel for a tab this build does not know. Never sent.
  unknown(null)
  ;

  const ProviderRequestTab(this._apiValue);

  final String? _apiValue;

  /// The wire value. Throws for [unknown], which must never be sent.
  String get apiValue =>
      _apiValue ??
      (throw StateError('ProviderRequestTab.unknown has no API value'));

  /// Parses a wire value, falling back to [unknown].
  static ProviderRequestTab fromApi(String? raw) {
    if (raw == null) return ProviderRequestTab.unknown;
    for (final value in ProviderRequestTab.values) {
      if (value._apiValue == raw) return value;
    }
    return ProviderRequestTab.unknown;
  }

  /// The tabs the workspace offers, in display order.
  static const List<ProviderRequestTab> ordered = [
    newRequest,
    yourTurn,
    awaitingClient,
    scheduled,
    inProgress,
    toConfirm,
    closed,
  ];

  /// The i18n key for this tab's label.
  String get labelKey => switch (this) {
    newRequest => 'provider_requests.tabs.new',
    awaitingClient => 'provider_requests.tabs.awaiting_client',
    yourTurn => 'provider_requests.tabs.your_turn',
    scheduled => 'provider_requests.tabs.scheduled',
    inProgress => 'provider_requests.tabs.in_progress',
    toConfirm => 'provider_requests.tabs.to_confirm',
    closed => 'provider_requests.tabs.closed',
    unknown => 'requests.status.unknown',
  };
}
