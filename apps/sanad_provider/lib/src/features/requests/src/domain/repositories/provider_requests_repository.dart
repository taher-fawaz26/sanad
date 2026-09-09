import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:requests_core/requests_core.dart';
import 'package:sanad_provider/src/features/requests/src/domain/entities/provider_request.dart';
import 'package:sanad_provider/src/features/requests/src/domain/entities/provider_request_summary.dart';
import 'package:sanad_provider/src/features/requests/src/domain/enums/provider_request_tab.dart';

/// Query for the workspace feed.
///
/// [tab] is sent to the server rather than applied locally: the tab is derived
/// from the request status *and* this provider's own thread, and a paginated
/// feed cannot be filtered after the fact without breaking the per-tab counts.
class ProviderRequestsQuery extends PageQuery {
  /// Creates a workspace query.
  const ProviderRequestsQuery({
    super.page,
    super.limit,
    super.search,
    this.tab,
    this.branchId,
  });

  /// The workspace tab to return. `null` means every tab.
  final ProviderRequestTab? tab;

  /// Narrows to requests matched to one branch.
  final String? branchId;

  @override
  Map<String, dynamic> toQueryMap() => {
    ...super.toQueryMap(),
    // `unknown` is a parse sentinel with no wire value and is never sent.
    if (tab != null && tab != ProviderRequestTab.unknown) 'tab': tab!.apiValue,
    if (branchId != null) 'branchId': branchId,
  };

  @override
  ProviderRequestsQuery copyWithPage(int page) => ProviderRequestsQuery(
    page: page,
    limit: limit,
    search: search,
    tab: tab,
    branchId: branchId,
  );

  @override
  List<Object?> get props => [...super.props, tab, branchId];
}

/// The body of `POST /provider/requests/:id/offers`.
class CreateOfferParams extends Equatable {
  /// Creates the parameters.
  const CreateOfferParams({
    required this.requestId,
    required this.branchId,
    required this.proposedAt,
    this.note,
  });

  /// The request being offered on.
  final String requestId;

  /// Which branch will do the work. Must be one that matched this request.
  final String branchId;

  /// Proposed start. Must be in the future — the server answers `400`
  /// otherwise.
  final DateTime proposedAt;

  /// Optional message, at most 1000 characters.
  final String? note;

  @override
  List<Object?> get props => [requestId, branchId, proposedAt, note];
}

/// The provider half of the request lifecycle.
abstract interface class ProviderRequestsRepository {
  /// `GET /provider/requests` — the workspace feed.
  TaskEither<Failure, Page<ProviderRequest>> list(ProviderRequestsQuery query);

  /// `GET /provider/requests/counts` — badge counts per tab.
  TaskEither<Failure, ProviderRequestCounts> counts();

  /// `GET /provider/requests/stats` — the four headline numbers.
  TaskEither<Failure, ProviderRequestStats> stats();

  /// `GET /provider/requests/:id`.
  ///
  /// A request never matched to one of this provider's branches answers `404`,
  /// indistinguishably from one that does not exist.
  TaskEither<Failure, ProviderRequest> getById(String id);

  /// `POST /provider/requests/:id/offers`.
  ///
  /// Answers `409` when the re-bid budget is exhausted, an offer is already
  /// live, or the request is closed.
  TaskEither<Failure, ProviderRequest> createOffer(CreateOfferParams params);

  /// `POST /provider/offers/:offerId/withdraw`.
  ///
  /// **Consumes a re-bid.** Send-and-withdraw is not a free retry.
  TaskEither<Failure, ProviderRequest> withdrawOffer({
    required String requestId,
    required String offerId,
  });

  /// `POST /provider/offers/:offerId/accept` — accepts the client's counter
  /// and books the job.
  TaskEither<Failure, ProviderRequest> acceptCounter({
    required String requestId,
    required String offerId,
  });

  /// `POST /provider/offers/:offerId/decline` — declines the client's counter.
  TaskEither<Failure, ProviderRequest> declineCounter({
    required String requestId,
    required String offerId,
  });

  /// `POST /provider/offers/:offerId/counter` — counters back with another
  /// time. The client's counter becomes SUPERSEDED, not REJECTED.
  TaskEither<Failure, ProviderRequest> counterOffer({
    required String requestId,
    required String offerId,
    required CounterOfferRequest body,
  });

  /// `POST /provider/requests/:id/complete` — moves the request to
  /// AWAITING_CONFIRMATION. It completes when the client confirms, or on a
  /// timer if they never do.
  TaskEither<Failure, ProviderRequest> complete(String requestId);

  /// `POST /provider/requests/:id/cancel` — cancels a won booking, with a
  /// required reason the client will read.
  TaskEither<Failure, ProviderRequest> cancel({
    required String requestId,
    required String reason,
  });
}
