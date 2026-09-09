import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';
import 'package:requests_core/requests_core.dart';
import 'package:sanad_client/src/features/client_requests/src/data/endpoints/client_requests_api_paths.dart';
import 'package:sanad_client/src/features/client_requests/src/data/models/client_request_dto.dart';
import 'package:sanad_client/src/features/client_requests/src/data/models/save_client_request_request.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/repositories/client_requests_repository.dart';

/// The HTTP surface of the client request lifecycle.
///
/// Every mutation answers with the full client-view request, so callers
/// always read the server's own post-action state instead of guessing.
abstract interface class ClientRequestsRemoteDataSource {
  /// `GET /requests`.
  TaskEither<Failure, Page<ClientRequestDto>> list(ClientRequestsQuery query);

  /// `GET /requests/:id`.
  TaskEither<Failure, ClientRequestDto> getById(String id);

  /// `POST /requests`.
  TaskEither<Failure, ClientRequestDto> create(SaveClientRequestRequest body);

  /// `PATCH /requests/:id`. Answers `409` once offers await a reply.
  TaskEither<Failure, ClientRequestDto> update(
    String id,
    SaveClientRequestRequest body,
  );

  /// `POST /requests/:id/submit`.
  TaskEither<Failure, ClientRequestDto> submit(String id);

  /// `POST /requests/:id/cancel`.
  TaskEither<Failure, ClientRequestDto> cancel(String id, ReasonRequest body);

  /// `POST /requests/:id/confirm`.
  TaskEither<Failure, ClientRequestDto> confirm(String id);

  /// `POST /requests/:id/dispute`.
  TaskEither<Failure, ClientRequestDto> dispute(String id, ReasonRequest body);

  /// `POST /requests/:id/offers/:offerId/accept`.
  TaskEither<Failure, ClientRequestDto> acceptOffer(
    String requestId,
    String offerId,
  );

  /// `POST /requests/:id/offers/:offerId/reject`.
  TaskEither<Failure, ClientRequestDto> rejectOffer(
    String requestId,
    String offerId,
  );

  /// `POST /requests/:id/offers/:offerId/counter`.
  TaskEither<Failure, ClientRequestDto> counterOffer(
    String requestId,
    String offerId,
    CounterOfferRequest body,
  );
}

/// Dio-backed [ClientRequestsRemoteDataSource].
class ClientRequestsRemoteDataSourceImpl
    implements ClientRequestsRemoteDataSource {
  /// Creates the data source.
  const ClientRequestsRemoteDataSourceImpl(this._apiClient);

  final BaseApiClient _apiClient;

  @override
  TaskEither<Failure, Page<ClientRequestDto>> list(ClientRequestsQuery query) =>
      _apiClient.request<Page<ClientRequestDto>>(
        path: ClientRequestsApiPaths.requests,
        method: RequestMethod.get,
        query: query.toQueryMap(),
        parser: (data) => parsePage(data, ClientRequestDto.fromJson),
      );

  @override
  TaskEither<Failure, ClientRequestDto> getById(String id) =>
      _request(ClientRequestsApiPaths.request(id), RequestMethod.get);

  @override
  TaskEither<Failure, ClientRequestDto> create(SaveClientRequestRequest body) =>
      _request(
        ClientRequestsApiPaths.requests,
        RequestMethod.post,
        body: body.toJson(),
      );

  @override
  TaskEither<Failure, ClientRequestDto> update(
    String id,
    SaveClientRequestRequest body,
  ) => _request(
    ClientRequestsApiPaths.request(id),
    RequestMethod.patch,
    body: body.toJson(),
  );

  @override
  TaskEither<Failure, ClientRequestDto> submit(String id) =>
      _request(ClientRequestsApiPaths.submit(id), RequestMethod.post);

  @override
  TaskEither<Failure, ClientRequestDto> cancel(String id, ReasonRequest body) =>
      _request(
        ClientRequestsApiPaths.cancel(id),
        RequestMethod.post,
        body: body.toJson(),
      );

  @override
  TaskEither<Failure, ClientRequestDto> confirm(String id) =>
      _request(ClientRequestsApiPaths.confirm(id), RequestMethod.post);

  @override
  TaskEither<Failure, ClientRequestDto> dispute(
    String id,
    ReasonRequest body,
  ) => _request(
    ClientRequestsApiPaths.dispute(id),
    RequestMethod.post,
    body: body.toJson(),
  );

  @override
  TaskEither<Failure, ClientRequestDto> acceptOffer(
    String requestId,
    String offerId,
  ) => _request(
    ClientRequestsApiPaths.acceptOffer(requestId, offerId),
    RequestMethod.post,
  );

  @override
  TaskEither<Failure, ClientRequestDto> rejectOffer(
    String requestId,
    String offerId,
  ) => _request(
    ClientRequestsApiPaths.rejectOffer(requestId, offerId),
    RequestMethod.post,
  );

  @override
  TaskEither<Failure, ClientRequestDto> counterOffer(
    String requestId,
    String offerId,
    CounterOfferRequest body,
  ) => _request(
    ClientRequestsApiPaths.counterOffer(requestId, offerId),
    RequestMethod.post,
    body: body.toJson(),
  );

  /// Every mutation answers with the full client-view request, so the caller
  /// always gets the server's own post-action state rather than predicting it.
  ///
  /// The offer actions are documented as `200` **or** `201`; the client does
  /// not branch on which, it just parses the body.
  TaskEither<Failure, ClientRequestDto> _request(
    String path,
    RequestMethod method, {
    Map<String, dynamic>? body,
  }) => _apiClient.request<ClientRequestDto>(
    path: path,
    method: method,
    body: body,
    parser: (data) =>
        ClientRequestDto.fromJson(data as Map<String, dynamic>? ?? const {}),
  );
}
