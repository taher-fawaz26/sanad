/// Client request-lifecycle endpoints.
///
/// Relative, no leading slash and no `/api/v1` prefix — the base URL already
/// ends in `/api/v1/`.
///
/// Every offer action is nested under its request: `:offerId` must belong to
/// the `:id` in the URL, and a mismatch answers `404`. Building the paths this
/// way makes it impossible to send an offer action without saying which request
/// it belongs to.
abstract final class ClientRequestsApiPaths {
  ClientRequestsApiPaths._();

  /// `GET` (list, optional `status`) and `POST` (create a draft).
  static const String requests = 'requests';

  /// `GET` one request, `PATCH` to edit it.
  static String request(String id) => 'requests/$id';

  /// `POST` — validate, match, and go live.
  static String submit(String id) => 'requests/$id/submit';

  /// `POST` — cancel with a required reason.
  static String cancel(String id) => 'requests/$id/cancel';

  /// `POST` — confirm the job was finished.
  static String confirm(String id) => 'requests/$id/confirm';

  /// `POST` — say the job was not done as claimed, with a required reason.
  static String dispute(String id) => 'requests/$id/dispute';

  /// `POST` — accept a provider's offer. Books the job and marks rivals LOST.
  static String acceptOffer(String id, String offerId) =>
      'requests/$id/offers/$offerId/accept';

  /// `POST` — decline one provider's offer. Ends that thread only.
  static String rejectOffer(String id, String offerId) =>
      'requests/$id/offers/$offerId/reject';

  /// `POST` — counter with a different time. Supersedes rather than rejects.
  static String counterOffer(String id, String offerId) =>
      'requests/$id/offers/$offerId/counter';
}
