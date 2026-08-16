part of 'request_details_bloc.dart';

class RequestDetailsState extends Equatable {
  const RequestDetailsState({
    required this.request,
    this.status = RequestStatus.initial,
    this.failure,
  });

  final RequestStatus status;

  /// Always populated — seeded from the route `extra` on construction, then
  /// replaced with the full detail once the fetch succeeds.
  final ServiceRequestEntity request;

  final Failure? failure;

  /// Covers both "never fetched yet" and "fetching" — the page skeletonizes
  /// the fields `request` doesn't have yet (matches the previous
  /// widget-owned `_isLoadingDetail = true` initial value).
  bool get isLoading =>
      status == RequestStatus.initial || status == RequestStatus.loading;

  RequestDetailsState copyWith({
    RequestStatus? status,
    ServiceRequestEntity? request,
    Failure? failure,
    bool clearFailure = false,
  }) => RequestDetailsState(
    status: status ?? this.status,
    request: request ?? this.request,
    failure: clearFailure ? null : (failure ?? this.failure),
  );

  @override
  List<Object?> get props => [status, request, failure];
}
