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
