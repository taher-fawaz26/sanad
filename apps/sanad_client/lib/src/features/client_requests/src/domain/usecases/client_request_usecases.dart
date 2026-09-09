import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:requests_core/requests_core.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/entities/catalogue_entities.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/entities/client_request.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/repositories/catalogue_repository.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/repositories/client_requests_repository.dart';

// ── Reads ───────────────────────────────────────────────────────────────────

/// Lists the client's own requests, newest first.
class ListClientRequestsUseCase
    implements UseCase<Page<ClientRequest>, ClientRequestsQuery> {
  /// Creates the use case.
  const ListClientRequestsUseCase(this._repository);

  final ClientRequestsRepository _repository;

  @override
  TaskEither<Failure, Page<ClientRequest>> call(ClientRequestsQuery params) =>
      _repository.list(params);
}

/// Reads one request with its offers and matched providers.
class GetClientRequestUseCase implements UseCase<ClientRequest, String> {
  /// Creates the use case.
  const GetClientRequestUseCase(this._repository);

  final ClientRequestsRepository _repository;

  @override
  TaskEither<Failure, ClientRequest> call(String params) =>
      _repository.getById(params);
}

// ── Draft lifecycle ─────────────────────────────────────────────────────────

/// Creates a DRAFT. Fields are optional at this stage.
class CreateDraftRequestUseCase
    implements UseCase<ClientRequest, SaveDraftParams> {
  /// Creates the use case.
  const CreateDraftRequestUseCase(this._repository);

  final ClientRequestsRepository _repository;

  @override
  TaskEither<Failure, ClientRequest> call(SaveDraftParams params) =>
      _repository.createDraft(params);
}

/// Identifies a request and the edits to apply to it.
class UpdateDraftParams extends Equatable {
  /// Creates the parameters.
  const UpdateDraftParams({required this.id, required this.changes});

  /// The request being edited.
  final String id;

  /// The fields to change. Anything omitted is left as it is.
  final SaveDraftParams changes;

  @override
  List<Object?> get props => [id];
}

/// Edits a request. Answers `409` once offers await a reply.
class UpdateDraftRequestUseCase
    implements UseCase<ClientRequest, UpdateDraftParams> {
  /// Creates the use case.
  const UpdateDraftRequestUseCase(this._repository);

  final ClientRequestsRepository _repository;

  @override
  TaskEither<Failure, ClientRequest> call(UpdateDraftParams params) =>
      _repository.update(params.id, params.changes);
}

/// Submits a draft for matching.
///
/// The `409` this can produce is *structured*: `NO_PROVIDERS_FOR_SERVICE`,
/// `NO_COVERAGE` or `OUTSIDE_HOURS`, the last carrying alternative windows.
/// Read it with [RequestSubmissionConflict.tryParse] instead of showing the raw
/// message — each code implies a different next action, and collapsing them
/// into one error string loses the whole point of the endpoint's design.
class SubmitRequestUseCase implements UseCase<ClientRequest, String> {
  /// Creates the use case.
  const SubmitRequestUseCase(this._repository);

  final ClientRequestsRepository _repository;

  @override
  TaskEither<Failure, ClientRequest> call(String params) =>
      _repository.submit(params);
}

// ── Request actions ─────────────────────────────────────────────────────────

/// A request id plus the reason an action requires.
class ReasonedRequestParams extends Equatable {
  /// Creates the parameters.
  const ReasonedRequestParams({required this.id, required this.reason});

  /// The request being acted on.
  final String id;

  /// Free text, 3-1000 characters. Shown to the other party verbatim.
  final String reason;

  @override
  List<Object?> get props => [id, reason];
}

/// Cancels a request with a recorded reason.
class CancelClientRequestUseCase
    implements UseCase<ClientRequest, ReasonedRequestParams> {
  /// Creates the use case.
  const CancelClientRequestUseCase(this._repository);

  final ClientRequestsRepository _repository;

  @override
  TaskEither<Failure, ClientRequest> call(ReasonedRequestParams params) =>
      _repository.cancel(params.id, params.reason);
}

/// Confirms the job was finished.
///
/// If the client never gets here the server auto-completes on a timer, so the
/// resulting status must always be read back from the response rather than
/// assumed.
class ConfirmClientRequestUseCase implements UseCase<ClientRequest, String> {
  /// Creates the use case.
  const ConfirmClientRequestUseCase(this._repository);

  final ClientRequestsRepository _repository;

  @override
  TaskEither<Failure, ClientRequest> call(String params) =>
      _repository.confirm(params);
}

/// Says the work was not done as claimed.
class DisputeClientRequestUseCase
    implements UseCase<ClientRequest, ReasonedRequestParams> {
  /// Creates the use case.
  const DisputeClientRequestUseCase(this._repository);

  final ClientRequestsRepository _repository;

  @override
  TaskEither<Failure, ClientRequest> call(ReasonedRequestParams params) =>
      _repository.dispute(params.id, params.reason);
}

// ── Offer actions ───────────────────────────────────────────────────────────

/// Identifies one offer inside one request.
class OfferActionParams extends Equatable {
  /// Creates the parameters.
  const OfferActionParams({required this.requestId, required this.offerId});

  /// The request in the URL. Required because the backend enforces that
  /// the offer belongs to it and answers `404` on a mismatch.
  final String requestId;

  /// The offer being acted on. Must belong to [requestId].
  final String offerId;

  @override
  List<Object?> get props => [requestId, offerId];
}

/// Accepts an offer: books the job and closes rival offers as LOST.
class AcceptOfferUseCase implements UseCase<ClientRequest, OfferActionParams> {
  /// Creates the use case.
  const AcceptOfferUseCase(this._repository);

  final ClientRequestsRepository _repository;

  @override
  TaskEither<Failure, ClientRequest> call(OfferActionParams params) =>
      _repository.acceptOffer(
        requestId: params.requestId,
        offerId: params.offerId,
      );
}

/// Declines one offer. Ends that thread only.
class RejectOfferUseCase implements UseCase<ClientRequest, OfferActionParams> {
  /// Creates the use case.
  const RejectOfferUseCase(this._repository);

  final ClientRequestsRepository _repository;

  @override
  TaskEither<Failure, ClientRequest> call(OfferActionParams params) =>
      _repository.rejectOffer(
        requestId: params.requestId,
        offerId: params.offerId,
      );
}

/// A counter-proposal against one offer.
class CounterOfferParams extends Equatable {
  /// Creates the parameters.
  const CounterOfferParams({
    required this.requestId,
    required this.offerId,
    required this.proposedAt,
    this.note,
  });

  /// The request the offer belongs to.
  final String requestId;

  /// The offer being countered.
  final String offerId;

  /// The time the client would prefer instead. Must be in the future.
  final DateTime proposedAt;

  /// Optional message, at most 1000 characters.
  final String? note;

  @override
  List<Object?> get props => [requestId, offerId, proposedAt, note];
}

/// Counters an offer. The provider offer becomes SUPERSEDED, not REJECTED.
class CounterOfferUseCase
    implements UseCase<ClientRequest, CounterOfferParams> {
  /// Creates the use case.
  const CounterOfferUseCase(this._repository);

  final ClientRequestsRepository _repository;

  @override
  TaskEither<Failure, ClientRequest> call(CounterOfferParams params) =>
      _repository.counterOffer(
        requestId: params.requestId,
        offerId: params.offerId,
        body: CounterOfferRequest(
          proposedAt: params.proposedAt,
          note: params.note,
        ),
      );
}

// ── Catalogue ───────────────────────────────────────────────────────────────

/// Browses the public service catalogue for the draft composer.
class BrowseCatalogueServicesUseCase
    implements UseCase<Page<CatalogueService>, CatalogueQuery> {
  /// Creates the use case.
  const BrowseCatalogueServicesUseCase(this._repository);

  final CatalogueRepository _repository;

  @override
  TaskEither<Failure, Page<CatalogueService>> call(CatalogueQuery params) =>
      _repository.services(params);
}

/// Reads catalogue categories.
class GetCatalogueCategoriesUseCase
    implements UseCase<Page<CatalogueCategory>, CatalogueQuery> {
  /// Creates the use case.
  const GetCatalogueCategoriesUseCase(this._repository);

  final CatalogueRepository _repository;

  @override
  TaskEither<Failure, Page<CatalogueCategory>> call(CatalogueQuery params) =>
      _repository.categories(params);
}
