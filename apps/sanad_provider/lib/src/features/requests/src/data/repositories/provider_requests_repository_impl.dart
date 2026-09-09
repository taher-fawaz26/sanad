import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:requests_core/requests_core.dart';
import 'package:sanad_provider/src/features/requests/src/data/datasources/provider_requests_remote_data_source.dart';
import 'package:sanad_provider/src/features/requests/src/domain/entities/provider_request.dart';
import 'package:sanad_provider/src/features/requests/src/domain/entities/provider_request_summary.dart';
import 'package:sanad_provider/src/features/requests/src/domain/repositories/provider_requests_repository.dart';

/// Maps provider-view DTOs to domain entities, and re-reads the request after
/// every mutation.
///
/// The re-read is not defensive padding. Accepting a client's counter unlocks
/// the contact block and changes the whole shape of what the provider may see,
/// and the mutation endpoints do not document a response body. Reading the
/// resource back is the only way to be sure the screen shows what the server
/// actually holds.
class ProviderRequestsRepositoryImpl implements ProviderRequestsRepository {
  /// Creates the repository.
  const ProviderRequestsRepositoryImpl(this._remote);

  final ProviderRequestsRemoteDataSource _remote;

  @override
  TaskEither<Failure, Page<ProviderRequest>> list(
    ProviderRequestsQuery query,
  ) =>
      _remote.list(query).map((page) => page.mapItems((dto) => dto.toEntity()));

  @override
  TaskEither<Failure, ProviderRequestCounts> counts() =>
      _remote.counts().map((dto) => dto.toEntity());

  @override
  TaskEither<Failure, ProviderRequestStats> stats() =>
      _remote.stats().map((dto) => dto.toEntity());

  @override
  TaskEither<Failure, ProviderRequest> getById(String id) =>
      _remote.getById(id).map((dto) => dto.toEntity());

  @override
  TaskEither<Failure, ProviderRequest> createOffer(CreateOfferParams params) {
    final note = params.note?.trim();
    return _thenReload(
      params.requestId,
      _remote.createOffer(params.requestId, {
        'branchId': params.branchId,
        'proposedAt': ApiDateTime.encode(params.proposedAt),
        if (note != null && note.isNotEmpty) 'note': note,
      }),
    );
  }

  @override
  TaskEither<Failure, ProviderRequest> withdrawOffer({
    required String requestId,
    required String offerId,
  }) => _thenReload(requestId, _remote.withdrawOffer(offerId));

  @override
  TaskEither<Failure, ProviderRequest> acceptCounter({
    required String requestId,
    required String offerId,
  }) => _thenReload(requestId, _remote.acceptOffer(offerId));

  @override
  TaskEither<Failure, ProviderRequest> declineCounter({
    required String requestId,
    required String offerId,
  }) => _thenReload(requestId, _remote.declineOffer(offerId));

  @override
  TaskEither<Failure, ProviderRequest> counterOffer({
    required String requestId,
    required String offerId,
    required CounterOfferRequest body,
  }) => _thenReload(
    requestId,
    _remote.counterOffer(offerId, body.toJson()),
  );

  @override
  TaskEither<Failure, ProviderRequest> complete(String requestId) =>
      _thenReload(requestId, _remote.complete(requestId));

  @override
  TaskEither<Failure, ProviderRequest> cancel({
    required String requestId,
    required String reason,
  }) => _thenReload(
    requestId,
    _remote.cancel(requestId, ReasonRequest(reason).toJson()),
  );

  /// Runs [action], then re-reads the request.
  ///
  /// A failed action short-circuits: the caller gets the action's own failure —
  /// including the structured `409` for an exhausted re-bid budget — rather
  /// than a misleading read error.
  TaskEither<Failure, ProviderRequest> _thenReload(
    String requestId,
    TaskEither<Failure, void> action,
  ) => action.flatMap((_) => getById(requestId));
}
