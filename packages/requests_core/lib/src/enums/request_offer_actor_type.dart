/// Who authored an offer node.
///
/// On the thread's pending offer this is the whole turn-taking rule: a pending
/// [provider] offer awaits the client, a pending [client] counter awaits the
/// provider. Neither side should re-derive whose turn it is from anything else.
enum RequestOfferActorType {
  provider('PROVIDER'),
  client('CLIENT'),

  /// Parse sentinel for an unrecognised server value. Never serialized.
  unknown(null)
  ;

  const RequestOfferActorType(this._apiValue);

  final String? _apiValue;

  String get apiValue =>
      _apiValue ??
      (throw StateError('RequestOfferActorType.unknown has no API value'));

  static RequestOfferActorType fromApi(String? raw) {
    if (raw == null) return RequestOfferActorType.unknown;
    for (final value in RequestOfferActorType.values) {
      if (value._apiValue == raw) return value;
    }
    return RequestOfferActorType.unknown;
  }
}
