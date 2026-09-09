import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';
import 'package:sanad_provider/src/features/requests/src/data/endpoints/provider_requests_api_paths.dart';
import 'package:sanad_provider/src/features/requests/src/data/models/provider_request_dto.dart';
import 'package:sanad_provider/src/features/requests/src/domain/repositories/provider_requests_repository.dart';

/// The HTTP surface of the provider request workspace.
abstract interface class ProviderRequestsRemoteDataSource {
  /// `GET /provider/requests`.
  TaskEither<Failure, Page<ProviderRequestDto>> list(
    ProviderRequestsQuery query,
  );

  /// `GET /provider/requests/counts`.
  TaskEither<Failure, ProviderRequestCountsDto> counts();

  /// `GET /provider/requests/stats`.
  TaskEither<Failure, ProviderRequestStatsDto> stats();

  /// `GET /provider/requests/:id`.
  TaskEither<Failure, ProviderRequestDto> getById(String id);

  /// `POST /provider/requests/:id/offers`.
  TaskEither<Failure, void> createOffer(
    String requestId,
    Map<String, dynamic> body,
  );

  /// `POST /provider/offers/:offerId/withdraw`.
  TaskEither<Failure, void> withdrawOffer(String offerId);

  /// `POST /provider/offers/:offerId/accept`.
  TaskEither<Failure, void> acceptOffer(String offerId);

  /// `POST /provider/offers/:offerId/decline`.
  TaskEither<Failure, void> declineOffer(String offerId);

  /// `POST /provider/offers/:offerId/counter`.
  TaskEither<Failure, void> counterOffer(
    String offerId,
    Map<String, dynamic> body,
  );

  /// `POST /provider/requests/:id/complete`.
  TaskEither<Failure, void> complete(String requestId);

  /// `POST /provider/requests/:id/cancel`.
  TaskEither<Failure, void> cancel(String requestId, Map<String, dynamic> body);
}

/// Dio-backed [ProviderRequestsRemoteDataSource].
///
/// The mutations parse **nothing**. Unlike the client endpoints, the provider
/// offer and job actions do not document a response body, and their `200`/`201`
/// carries no guarantee of one. The repository re-reads the request afterwards
/// instead — which is also the correct thing to do regardless, since accepting
/// a counter changes the contact gate and the whole view along with it.
class ProviderRequestsRemoteDataSourceImpl
    implements ProviderRequestsRemoteDataSource {
  /// Creates the data source.
  const ProviderRequestsRemoteDataSourceImpl(this._apiClient);

  final BaseApiClient _apiClient;

  @override
  TaskEither<Failure, Page<ProviderRequestDto>> list(
    ProviderRequestsQuery query,
  ) => _apiClient.request<Page<ProviderRequestDto>>(
    path: ProviderRequestsApiPaths.requests,
    method: RequestMethod.get,
    query: query.toQueryMap(),
    parser: (data) => parsePage(data, ProviderRequestDto.fromJson),
  );

  @override
  TaskEither<Failure, ProviderRequestCountsDto> counts() =>
      _apiClient.request<ProviderRequestCountsDto>(
        path: ProviderRequestsApiPaths.counts,
        method: RequestMethod.get,
        parser: (data) => ProviderRequestCountsDto.fromJson(
          data as Map<String, dynamic>? ?? const {},
        ),
      );

  @override
  TaskEither<Failure, ProviderRequestStatsDto> stats() =>
      _apiClient.request<ProviderRequestStatsDto>(
        path: ProviderRequestsApiPaths.stats,
        method: RequestMethod.get,
        parser: (data) => ProviderRequestStatsDto.fromJson(
          data as Map<String, dynamic>? ?? const {},
        ),
      );

  @override
  TaskEither<Failure, ProviderRequestDto> getById(String id) =>
      _apiClient.request<ProviderRequestDto>(
        path: ProviderRequestsApiPaths.request(id),
        method: RequestMethod.get,
        parser: (data) => ProviderRequestDto.fromJson(
          data as Map<String, dynamic>? ?? const {},
        ),
      );

  @override
  TaskEither<Failure, void> createOffer(
    String requestId,
    Map<String, dynamic> body,
  ) => _post(ProviderRequestsApiPaths.createOffer(requestId), body: body);

  @override
  TaskEither<Failure, void> withdrawOffer(String offerId) =>
      _post(ProviderRequestsApiPaths.withdrawOffer(offerId));

  @override
  TaskEither<Failure, void> acceptOffer(String offerId) =>
      _post(ProviderRequestsApiPaths.acceptOffer(offerId));

  @override
  TaskEither<Failure, void> declineOffer(String offerId) =>
      _post(ProviderRequestsApiPaths.declineOffer(offerId));

  @override
  TaskEither<Failure, void> counterOffer(
    String offerId,
    Map<String, dynamic> body,
  ) => _post(ProviderRequestsApiPaths.counterOffer(offerId), body: body);

  @override
  TaskEither<Failure, void> complete(String requestId) =>
      _post(ProviderRequestsApiPaths.complete(requestId));

  @override
  TaskEither<Failure, void> cancel(
    String requestId,
    Map<String, dynamic> body,
  ) => _post(ProviderRequestsApiPaths.cancel(requestId), body: body);

  TaskEither<Failure, void> _post(
    String path, {
    Map<String, dynamic>? body,
  }) => _apiClient.request<void>(
    path: path,
    method: RequestMethod.post,
    body: body,
    parser: (_) {},
  );
}
