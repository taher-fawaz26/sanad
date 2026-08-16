part of 'service_details_bloc.dart';

sealed class ServiceDetailsEvent extends Equatable {
  const ServiceDetailsEvent();

  @override
  List<Object?> get props => [];
}

/// Fetches (or re-fetches, on retry) the service by [serviceId].
final class ServiceDetailsFetchRequested extends ServiceDetailsEvent {
  const ServiceDetailsFetchRequested(this.serviceId);

  final String serviceId;

  @override
  List<Object?> get props => [serviceId];
}

/// See [ServiceDetailsBloc._onExternallyUpdated].
final class ServiceDetailsExternallyUpdated extends ServiceDetailsEvent {
  const ServiceDetailsExternallyUpdated(this.service);

  final ProviderServiceEntity service;

  @override
  List<Object?> get props => [service];
}
