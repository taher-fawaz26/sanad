part of 'service_analytics_bloc.dart';

class ServiceAnalyticsState extends Equatable {
  const ServiceAnalyticsState({
    this.status = RequestStatus.initial,
    this.analytics,
    this.failure,
  });

  final RequestStatus status;
  final ServiceAnalyticsEntity? analytics;
  final Failure? failure;

  bool get isLoading => status == RequestStatus.loading;
  bool get hasError => status == RequestStatus.failure;

  /// `true` only once loaded successfully and the backend reports real data.
  bool get hasAvailableData =>
      status == RequestStatus.success && (analytics?.dataAvailable ?? false);

  ServiceAnalyticsState copyWith({
    RequestStatus? status,
    ServiceAnalyticsEntity? analytics,
    Failure? failure,
    bool clearFailure = false,
  }) => ServiceAnalyticsState(
    status: status ?? this.status,
    analytics: analytics ?? this.analytics,
    failure: clearFailure ? null : (failure ?? this.failure),
  );

  @override
  List<Object?> get props => [status, analytics, failure];
}
