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
    required this.isActive,
  });

  final String serviceId;
  final bool isActive;

  @override
  List<Object?> get props => [serviceId, isActive];
}
