part of 'service_requests_list_bloc.dart';

class ServiceRequestsListState extends Equatable {
  const ServiceRequestsListState({
    this.status = RequestStatus.initial,
    this.requests = const <ServiceRequestEntity>[],
    this.searchQuery = '',
    this.statusFilter = ServiceRequestStatus.all,
    this.failure,
    this.page = 1,
    this.totalPages = 1,
    this.loadingMore = false,
  });

  final RequestStatus status;
  final List<ServiceRequestEntity> requests;
  final String searchQuery;
  final ServiceRequestStatus statusFilter;
  final Failure? failure;
  final int page;
  final int totalPages;
  final bool loadingMore;

  bool get isLoading => status == RequestStatus.loading;
  bool get hasError => status == RequestStatus.failure;
  bool get hasMore => page < totalPages;

  ServiceRequestsListState copyWith({
    RequestStatus? status,
    List<ServiceRequestEntity>? requests,
    String? searchQuery,
    ServiceRequestStatus? statusFilter,
    Failure? failure,
    int? page,
    int? totalPages,
    bool? loadingMore,
    bool clearFailure = false,
  }) => ServiceRequestsListState(
    status: status ?? this.status,
    requests: requests ?? this.requests,
    searchQuery: searchQuery ?? this.searchQuery,
    statusFilter: statusFilter ?? this.statusFilter,
    failure: clearFailure ? null : (failure ?? this.failure),
    page: page ?? this.page,
    totalPages: totalPages ?? this.totalPages,
    loadingMore: loadingMore ?? this.loadingMore,
  );

  @override
  List<Object?> get props => [
    status,
    requests,
    searchQuery,
    statusFilter,
    failure,
    page,
    totalPages,
    loadingMore,
  ];
}
