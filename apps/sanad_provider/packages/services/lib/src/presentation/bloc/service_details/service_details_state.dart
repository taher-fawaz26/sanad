part of 'service_details_bloc.dart';

class ServiceDetailsState extends Equatable {
  const ServiceDetailsState({
    this.status = RequestStatus.initial,
    this.serviceId,
    this.service,
    this.failure,
  });

  final RequestStatus status;

  /// Set on the first [ServiceDetailsFetchRequested] and retained across
  /// failures, so a retry always knows which id to re-fetch even though
  /// [service] itself is still null.
  final String? serviceId;
  final ProviderServiceEntity? service;
  final Failure? failure;

  /// Covers both "never fetched yet" and "fetching" — the page skeletonizes
  /// for both, matching the previous widget-owned `_isLoading = true`
  /// initial value.
  bool get isLoading =>
      status == RequestStatus.initial || status == RequestStatus.loading;

  bool get hasError => status == RequestStatus.failure;

  ServiceDetailsState copyWith({
    RequestStatus? status,
    String? serviceId,
    ProviderServiceEntity? service,
    Failure? failure,
    bool clearFailure = false,
  }) => ServiceDetailsState(
    status: status ?? this.status,
    serviceId: serviceId ?? this.serviceId,
    service: service ?? this.service,
    failure: clearFailure ? null : (failure ?? this.failure),
  );

  @override
  List<Object?> get props => [status, serviceId, service, failure];
}
