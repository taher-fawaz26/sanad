part of 'service_analytics_bloc.dart';

class ServiceAnalyticsState extends Equatable {
  const ServiceAnalyticsState({
    this.status = RequestStatus.initial,
    this.overview,
    this.failure,
  });

  final RequestStatus status;
  final ProviderServiceOverviewEntity? overview;
  final Failure? failure;

  bool get isLoading => status == RequestStatus.loading;
  bool get hasError => status == RequestStatus.failure;

  /// `true` only once loaded successfully and the backend reports real data.
  bool get hasAvailableData =>
      status == RequestStatus.success && (overview?.dataAvailable ?? false);

  ServiceAnalyticsState copyWith({
    RequestStatus? status,
    ProviderServiceOverviewEntity? overview,
    Failure? failure,
    bool clearFailure = false,
  }) => ServiceAnalyticsState(
    status: status ?? this.status,
    overview: overview ?? this.overview,
    failure: clearFailure ? null : (failure ?? this.failure),
  );

  @override
  List<Object?> get props => [status, overview, failure];
}
