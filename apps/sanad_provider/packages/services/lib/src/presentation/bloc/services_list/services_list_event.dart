part of 'services_list_bloc.dart';

sealed class ServicesListEvent extends Equatable {
  const ServicesListEvent();

  @override
  List<Object?> get props => [];
}

final class ServicesListFetchEvent extends ServicesListEvent {
  const ServicesListFetchEvent();
}

final class ServicesListRefreshEvent extends ServicesListEvent {
  const ServicesListRefreshEvent();
}

final class ServicesListLoadMoreEvent extends ServicesListEvent {
  const ServicesListLoadMoreEvent();
}

final class ServicesListSearchChangedEvent extends ServicesListEvent {
  const ServicesListSearchChangedEvent(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

/// Folds a mutated service (status toggle) back into the list, sent by the
/// page after [ServiceActionBloc] succeeds.
final class ServiceReplacedInListEvent extends ServicesListEvent {
  const ServiceReplacedInListEvent(this.service);

  final ServiceRecordEntity service;

  @override
  List<Object?> get props => [service];
}

/// Removes a deleted service from the list, sent by the page after
/// [ServiceActionBloc] succeeds.
final class ServiceRemovedFromListEvent extends ServicesListEvent {
  const ServiceRemovedFromListEvent(this.serviceId);

  final String serviceId;

  @override
  List<Object?> get props => [serviceId];
}
