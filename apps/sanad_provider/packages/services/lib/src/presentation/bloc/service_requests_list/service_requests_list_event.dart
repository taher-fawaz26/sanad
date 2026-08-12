part of 'service_requests_list_bloc.dart';

sealed class ServiceRequestsListEvent extends Equatable {
  const ServiceRequestsListEvent();

  @override
  List<Object?> get props => [];
}

final class ServiceRequestsListFetchEvent extends ServiceRequestsListEvent {
  const ServiceRequestsListFetchEvent();
}

final class ServiceRequestsListRefreshEvent extends ServiceRequestsListEvent {
  const ServiceRequestsListRefreshEvent();
}

final class ServiceRequestsListLoadMoreEvent extends ServiceRequestsListEvent {
  const ServiceRequestsListLoadMoreEvent();
}

final class ServiceRequestsListSearchChangedEvent
    extends ServiceRequestsListEvent {
  const ServiceRequestsListSearchChangedEvent(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

final class ServiceRequestsListStatusChangedEvent
    extends ServiceRequestsListEvent {
  const ServiceRequestsListStatusChangedEvent(this.status);

  final ServiceRequestStatus status;

  @override
  List<Object?> get props => [status];
}
