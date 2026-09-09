import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:requests_core/requests_core.dart';
import 'package:sanad_client/src/features/client_requests/src/data/datasources/client_requests_remote_data_source.dart';
import 'package:sanad_client/src/features/client_requests/src/data/models/save_client_request_request.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/entities/client_request.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/repositories/client_requests_repository.dart';

/// Maps request DTOs to domain entities.
class ClientRequestsRepositoryImpl implements ClientRequestsRepository {
  /// Creates the repository.
  const ClientRequestsRepositoryImpl(this._remote);

  final ClientRequestsRemoteDataSource _remote;

  @override
  TaskEither<Failure, Page<ClientRequest>> list(ClientRequestsQuery query) =>
      _remote.list(query).map((page) => page.mapItems((dto) => dto.toEntity()));

  @override
  TaskEither<Failure, ClientRequest> getById(String id) =>
      _remote.getById(id).map((dto) => dto.toEntity());

  @override
  TaskEither<Failure, ClientRequest> createDraft(SaveDraftParams params) =>
      _remote.create(_body(params)).map((dto) => dto.toEntity());

  @override
  TaskEither<Failure, ClientRequest> update(
    String id,
    SaveDraftParams params,
  ) => _remote.update(id, _body(params)).map((dto) => dto.toEntity());

  @override
  TaskEither<Failure, ClientRequest> submit(String id) =>
      _remote.submit(id).map((dto) => dto.toEntity());

  @override
  TaskEither<Failure, ClientRequest> cancel(String id, String reason) =>
      _remote.cancel(id, ReasonRequest(reason)).map((dto) => dto.toEntity());

  @override
  TaskEither<Failure, ClientRequest> confirm(String id) =>
      _remote.confirm(id).map((dto) => dto.toEntity());

  @override
  TaskEither<Failure, ClientRequest> dispute(String id, String reason) =>
      _remote.dispute(id, ReasonRequest(reason)).map((dto) => dto.toEntity());

  @override
  TaskEither<Failure, ClientRequest> acceptOffer({
    required String requestId,
    required String offerId,
  }) => _remote.acceptOffer(requestId, offerId).map((dto) => dto.toEntity());

  @override
  TaskEither<Failure, ClientRequest> rejectOffer({
    required String requestId,
    required String offerId,
  }) => _remote.rejectOffer(requestId, offerId).map((dto) => dto.toEntity());

  @override
  TaskEither<Failure, ClientRequest> counterOffer({
    required String requestId,
    required String offerId,
    required CounterOfferRequest body,
  }) => _remote
      .counterOffer(requestId, offerId, body)
      .map((dto) => dto.toEntity());

  static SaveClientRequestRequest _body(SaveDraftParams params) =>
      SaveClientRequestRequest(
        serviceId: params.serviceId,
        lat: params.lat,
        lng: params.lng,
        addressLine: params.addressLine,
        preferredAt: params.preferredAt,
        note: params.note,
        mediaIds: params.mediaIds,
      );
}
