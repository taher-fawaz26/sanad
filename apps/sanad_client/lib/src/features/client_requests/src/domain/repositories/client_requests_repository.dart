import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:requests_core/requests_core.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/entities/client_request.dart';

/// Query for `GET /requests`. `limit` is capped at 100 by [PageQuery].
class ClientRequestsQuery extends PageQuery {
  /// Creates a list query.
  const ClientRequestsQuery({super.page, super.limit, this.status});

  /// Optional server-side status filter. `null` means all statuses.
  final ClientRequestStatus? status;

  @override
  Map<String, dynamic> toQueryMap() => {
    ...super.toQueryMap(),
    // `unknown` is a parse sentinel with no wire value, so it is never sent.
    if (status != null && status != ClientRequestStatus.unknown)
      'status': status!.apiValue,
  };

  @override
  ClientRequestsQuery copyWithPage(int page) =>
      ClientRequestsQuery(page: page, limit: limit, status: status);

  @override
  List<Object?> get props => [...super.props, status];
}

/// The fields a draft save may carry. All optional — a partial draft is valid.
class SaveDraftParams {
  /// Creates a set of draft edits. Omitted fields are left untouched
  /// server-side rather than cleared.
  const SaveDraftParams({
    this.serviceId,
    this.lat,
    this.lng,
    this.addressLine,
    this.preferredAt,
    this.note,
    this.mediaIds,
  });

  /// Catalogue service id.
  final String? serviceId;

  /// Job latitude.
  final double? lat;

  /// Job longitude.
  final double? lng;

  /// Street address entered by the client.
  final String? addressLine;

  /// Requested start time.
  final DateTime? preferredAt;

  /// Description of the job.
  final String? note;

  /// Replaces the whole attachment set when non-null.
  final List<String>? mediaIds;
}

/// The client half of the request lifecycle.
///
/// Every offer action takes both the request id and the offer id, because the
/// backend enforces that the offer belongs to the request in the URL and
/// answers `404` on a mismatch. Threading both through the signature makes that
/// impossible to get wrong at a call site.
abstract interface class ClientRequestsRepository {
  /// `GET /requests` — the caller's own requests only.
  TaskEither<Failure, Page<ClientRequest>> list(ClientRequestsQuery query);

  /// `GET /requests/:id`. Another client's request answers `404`,
  /// never `403`.
  TaskEither<Failure, ClientRequest> getById(String id);

  /// `POST /requests` — creates a DRAFT. Nothing is validated beyond
  /// field shapes, so a partial draft is fine.
  TaskEither<Failure, ClientRequest> createDraft(SaveDraftParams params);

  /// Edits a request. Answers `409` once offers are awaiting a reply or the
  /// request is closed — the UI must stop treating it as editable and re-read.
  TaskEither<Failure, ClientRequest> update(String id, SaveDraftParams params);

  /// Validates, matches and goes live.
  ///
  /// A `409` here is a *structured* matching failure — read it with
  /// [RequestSubmissionConflict.tryParse] rather than showing the raw message,
  /// because each code implies a different next action.
  TaskEither<Failure, ClientRequest> submit(String id);

  /// `POST /requests/:id/cancel` with a required 3-1000 char reason.
  TaskEither<Failure, ClientRequest> cancel(String id, String reason);

  /// `POST /requests/:id/confirm`. If the client never gets here the
  /// server auto-completes on a timer instead.
  TaskEither<Failure, ClientRequest> confirm(String id);

  /// `POST /requests/:id/dispute`. The reason is shown to the provider
  /// verbatim.
  TaskEither<Failure, ClientRequest> dispute(String id, String reason);

  /// Accepts an offer: books the job, sets `scheduledAt`, and closes every
  /// rival offer as LOST.
  TaskEither<Failure, ClientRequest> acceptOffer({
    required String requestId,
    required String offerId,
  });

  /// Declines one provider's offer. Ends that thread only — others continue.
  TaskEither<Failure, ClientRequest> rejectOffer({
    required String requestId,
    required String offerId,
  });

  /// Counters with a different time. The provider's offer becomes SUPERSEDED,
  /// not REJECTED, and this proposal becomes the thread's pending node.
  TaskEither<Failure, ClientRequest> counterOffer({
    required String requestId,
    required String offerId,
    required CounterOfferRequest body,
  });
}
