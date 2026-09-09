import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:requests_core/requests_core.dart';
import 'package:sanad_provider/src/features/requests/src/domain/entities/provider_request.dart';
import 'package:sanad_provider/src/features/requests/src/domain/entities/provider_request_summary.dart';
import 'package:sanad_provider/src/features/requests/src/domain/repositories/provider_requests_repository.dart';

/// The workspace feed, filtered by the server-derived tab.
class ListProviderRequestsUseCase
    implements UseCase<Page<ProviderRequest>, ProviderRequestsQuery> {
  /// Creates the use case.
  const ListProviderRequestsUseCase(this._repository);

  final ProviderRequestsRepository _repository;

  @override
  TaskEither<Failure, Page<ProviderRequest>> call(
    ProviderRequestsQuery params,
  ) => _repository.list(params);
}

/// Badge counts, one per workspace tab.
class GetProviderRequestCountsUseCase
    implements UseCase<ProviderRequestCounts, NoParams> {
  /// Creates the use case.
  const GetProviderRequestCountsUseCase(this._repository);

  final ProviderRequestsRepository _repository;

  @override
  TaskEither<Failure, ProviderRequestCounts> call(NoParams params) =>
      _repository.counts();
}

/// The four headline numbers above the workspace.
class GetProviderRequestStatsUseCase
    implements UseCase<ProviderRequestStats, NoParams> {
  /// Creates the use case.
  const GetProviderRequestStatsUseCase(this._repository);

  final ProviderRequestsRepository _repository;

  @override
  TaskEither<Failure, ProviderRequestStats> call(NoParams params) =>
      _repository.stats();
}

/// One request, in the provider view.
class GetProviderRequestUseCase implements UseCase<ProviderRequest, String> {
  /// Creates the use case.
  const GetProviderRequestUseCase(this._repository);

  final ProviderRequestsRepository _repository;

  @override
  TaskEither<Failure, ProviderRequest> call(String params) =>
      _repository.getById(params);
}

/// Offers to do the job, from a matched branch, at a future time.
class CreateProviderOfferUseCase
    implements UseCase<ProviderRequest, CreateOfferParams> {
  /// Creates the use case.
  const CreateProviderOfferUseCase(this._repository);

  final ProviderRequestsRepository _repository;

  @override
  TaskEither<Failure, ProviderRequest> call(CreateOfferParams params) =>
      _repository.createOffer(params);
}

/// Identifies one of this provider's offers, and the request it belongs to.
///
/// The URL needs only the offer id, but the request id is carried so the
/// repository can re-read the resource afterwards.
class ProviderOfferActionParams extends Equatable {
  /// Creates the parameters.
  const ProviderOfferActionParams({
    required this.requestId,
    required this.offerId,
  });

  /// The request the offer belongs to.
  final String requestId;

  /// The offer being acted on.
  final String offerId;

  @override
  List<Object?> get props => [requestId, offerId];
}

/// Pulls back a pending offer. **Consumes a re-bid.**
class WithdrawProviderOfferUseCase
    implements UseCase<ProviderRequest, ProviderOfferActionParams> {
  /// Creates the use case.
  const WithdrawProviderOfferUseCase(this._repository);

  final ProviderRequestsRepository _repository;

  @override
  TaskEither<Failure, ProviderRequest> call(ProviderOfferActionParams params) =>
      _repository.withdrawOffer(
        requestId: params.requestId,
        offerId: params.offerId,
      );
}

/// Accepts the client's counter and books the job.
class AcceptClientCounterUseCase
    implements UseCase<ProviderRequest, ProviderOfferActionParams> {
  /// Creates the use case.
  const AcceptClientCounterUseCase(this._repository);

  final ProviderRequestsRepository _repository;

  @override
  TaskEither<Failure, ProviderRequest> call(ProviderOfferActionParams params) =>
      _repository.acceptCounter(
        requestId: params.requestId,
        offerId: params.offerId,
      );
}

/// Declines the client's counter.
class DeclineClientCounterUseCase
    implements UseCase<ProviderRequest, ProviderOfferActionParams> {
  /// Creates the use case.
  const DeclineClientCounterUseCase(this._repository);

  final ProviderRequestsRepository _repository;

  @override
  TaskEither<Failure, ProviderRequest> call(ProviderOfferActionParams params) =>
      _repository.declineCounter(
        requestId: params.requestId,
        offerId: params.offerId,
      );
}

/// A provider counter-proposal against the client's counter.
class ProviderCounterParams extends Equatable {
  /// Creates the parameters.
  const ProviderCounterParams({
    required this.requestId,
    required this.offerId,
    required this.proposedAt,
    this.note,
  });

  /// The request the offer belongs to.
  final String requestId;

  /// The client counter being answered.
  final String offerId;

  /// The time this provider proposes instead. Must be in the future.
  final DateTime proposedAt;

  /// Optional message, at most 1000 characters.
  final String? note;

  @override
  List<Object?> get props => [requestId, offerId, proposedAt, note];
}

/// Counters the client's counter. Supersedes it rather than rejecting it.
class CounterClientOfferUseCase
    implements UseCase<ProviderRequest, ProviderCounterParams> {
  /// Creates the use case.
  const CounterClientOfferUseCase(this._repository);

  final ProviderRequestsRepository _repository;

  @override
  TaskEither<Failure, ProviderRequest> call(ProviderCounterParams params) =>
      _repository.counterOffer(
        requestId: params.requestId,
        offerId: params.offerId,
        body: CounterOfferRequest(
          proposedAt: params.proposedAt,
          note: params.note,
        ),
      );
}

/// Marks the job finished, moving it to AWAITING_CONFIRMATION.
class CompleteProviderJobUseCase implements UseCase<ProviderRequest, String> {
  /// Creates the use case.
  const CompleteProviderJobUseCase(this._repository);

  final ProviderRequestsRepository _repository;

  @override
  TaskEither<Failure, ProviderRequest> call(String params) =>
      _repository.complete(params);
}

/// A booking cancellation and the reason the client will read.
class CancelProviderJobParams extends Equatable {
  /// Creates the parameters.
  const CancelProviderJobParams({
    required this.requestId,
    required this.reason,
  });

  /// The booking being cancelled.
  final String requestId;

  /// Free text, 3-1000 characters. Shown to the client verbatim.
  final String reason;

  @override
  List<Object?> get props => [requestId, reason];
}

/// Cancels a booking this provider won.
class CancelProviderJobUseCase
    implements UseCase<ProviderRequest, CancelProviderJobParams> {
  /// Creates the use case.
  const CancelProviderJobUseCase(this._repository);

  final ProviderRequestsRepository _repository;

  @override
  TaskEither<Failure, ProviderRequest> call(CancelProviderJobParams params) =>
      _repository.cancel(
        requestId: params.requestId,
        reason: params.reason,
      );
}
