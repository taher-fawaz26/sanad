part of 'service_analytics_bloc.dart';

sealed class ServiceAnalyticsEvent extends Equatable {
  const ServiceAnalyticsEvent();

  @override
  List<Object?> get props => [];
}

final class ServiceAnalyticsFetchEvent extends ServiceAnalyticsEvent {
  const ServiceAnalyticsFetchEvent();
}
