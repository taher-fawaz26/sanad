/// Provider request-workspace endpoints.
///
/// Relative, no leading slash and no `/api/v1` prefix — the base URL already
/// ends in `/api/v1/`.
///
/// Note the asymmetry with the client side: creating an offer and the two job
/// actions are nested under a **request**, while acting on an existing offer is
/// addressed by **offer id alone**. That is the backend's shape, not a
/// simplification — a provider only ever has one thread per request, so the
/// offer id is already unambiguous.
abstract final class ProviderRequestsApiPaths {
  ProviderRequestsApiPaths._();

  /// `GET` — the workspace feed, filtered by `tab`, `search` and `branchId`.
  static const String requests = 'provider/requests';

  /// `GET` — badge counts, one per workspace tab.
  static const String counts = 'provider/requests/counts';

  /// `GET` — the four headline numbers.
  static const String stats = 'provider/requests/stats';

  /// `GET` — one request in the provider view.
  static String request(String id) => 'provider/requests/$id';

  /// `POST` — offer to do the job, from a matched branch, at a future time.
  static String createOffer(String id) => 'provider/requests/$id/offers';

  /// `POST` — mark the job finished. Moves it to AWAITING_CONFIRMATION.
  static String complete(String id) => 'provider/requests/$id/complete';

  /// `POST` — cancel a booking, with a required reason.
  static String cancel(String id) => 'provider/requests/$id/cancel';

  /// `POST` — pull back a pending offer. Consumes a re-bid.
  static String withdrawOffer(String offerId) =>
      'provider/offers/$offerId/withdraw';

  /// `POST` — accept the client's counter and book the job.
  static String acceptOffer(String offerId) =>
      'provider/offers/$offerId/accept';

  /// `POST` — decline the client's counter.
  static String declineOffer(String offerId) =>
      'provider/offers/$offerId/decline';

  /// `POST` — counter the client's counter with another time.
  static String counterOffer(String offerId) =>
      'provider/offers/$offerId/counter';
}
