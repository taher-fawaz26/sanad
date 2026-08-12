part of 'services_list_bloc.dart';

class ServicesListState extends Equatable {
  const ServicesListState({
    this.status = RequestStatus.initial,
    this.services = const <ProviderServiceEntity>[],
    this.searchQuery = '',
    this.statusFilter = ProviderServiceStatus.all,
    this.failure,
    this.page = 1,
    this.totalPages = 1,
    this.loadingMore = false,
  });

  final RequestStatus status;
  final List<ProviderServiceEntity> services;
  final String searchQuery;
  final ProviderServiceStatus statusFilter;
  final Failure? failure;
  final int page;
  final int totalPages;
  final bool loadingMore;

  bool get isLoading => status == RequestStatus.loading;
  bool get hasError => status == RequestStatus.failure;
  bool get hasMore => page < totalPages;

  ServicesListState copyWith({
    RequestStatus? status,
    List<ProviderServiceEntity>? services,
    String? searchQuery,
    ProviderServiceStatus? statusFilter,
    Failure? failure,
    int? page,
    int? totalPages,
    bool? loadingMore,
    bool clearFailure = false,
  }) => ServicesListState(
    status: status ?? this.status,
    services: services ?? this.services,
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
    services,
    searchQuery,
    statusFilter,
    failure,
    page,
    totalPages,
    loadingMore,
  ];
}
