part of 'service_action_bloc.dart';

sealed class ServiceActionEvent extends Equatable {
  const ServiceActionEvent();

  @override
  List<Object?> get props => [];
}

final class ServiceDeleteRequestedEvent extends ServiceActionEvent {
  const ServiceDeleteRequestedEvent(this.serviceId);

  final String serviceId;

  @override
  List<Object?> get props => [serviceId];
}

final class ServiceStatusToggleRequestedEvent extends ServiceActionEvent {
  const ServiceStatusToggleRequestedEvent({
    required this.serviceId,
    required this.status,
  });

  final String serviceId;
  final ProviderServiceStatus status;

  @override
  List<Object?> get props => [serviceId, status];
}

/// Notifies this bloc's listeners (the dashboard list, the details page)
/// that [service] changed via a flow this bloc doesn't own directly — the
/// real mutation already happened via [EditServiceBloc]'s
/// `PATCH /provider-services/{id}`; this just re-broadcasts the result
/// through the same `updatedService` plumbing
/// [ServiceStatusToggleRequestedEvent]/[ServiceDeleteRequestedEvent] already
/// use, so both pages fold it in the same way regardless of which one
/// presented the actions sheet.
final class ServiceExternallyUpdatedEvent extends ServiceActionEvent {
  const ServiceExternallyUpdatedEvent(this.service);

  final ProviderServiceEntity service;

  @override
  List<Object?> get props => [service];
}
