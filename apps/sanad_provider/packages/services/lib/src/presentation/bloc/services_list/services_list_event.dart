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

final class ServicesListStatusChangedEvent extends ServicesListEvent {
  const ServicesListStatusChangedEvent(this.status);

  final ProviderServiceStatus status;

  @override
  List<Object?> get props => [status];
}

/// Client-side category filter, applied over the already-loaded
/// `GET /provider-services` page (that endpoint has no `categoryId` query
/// param — confirmed against the live API contract). `null` clears the
/// filter and shows every loaded service again.
final class ServicesListCategoryChangedEvent extends ServicesListEvent {
  const ServicesListCategoryChangedEvent(this.categoryId);

  final String? categoryId;

  @override
  List<Object?> get props => [categoryId];
}

/// Folds a mutated service (status toggle) back into the list, sent by the
/// page after [ServiceActionBloc] succeeds.
final class ServiceReplacedInListEvent extends ServicesListEvent {
  const ServiceReplacedInListEvent(this.service);

  final ProviderServiceEntity service;

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
