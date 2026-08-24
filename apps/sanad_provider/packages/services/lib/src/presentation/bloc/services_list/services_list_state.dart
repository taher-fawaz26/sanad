part of 'services_list_bloc.dart';

class ServicesListState extends Equatable {
  const ServicesListState({
    this.pagination = const PaginationData<ProviderServiceEntity>(),
    this.searchQuery = '',
    this.statusFilter = ProviderServiceStatus.all,
    this.selectedCategoryId,
  });

  final PaginationData<ProviderServiceEntity> pagination;
  final String searchQuery;
  final ProviderServiceStatus statusFilter;

  /// `category.id` to filter the loaded list by, or `null` to show every
  /// loaded service — see [ServicesListCategoryChangedEvent].
  final String? selectedCategoryId;

  List<ProviderServiceEntity> get services => pagination.items;

  /// [services] narrowed to [selectedCategoryId], or all of [services] when
  /// no category is selected. Status/search are already applied server-side
  /// (see `ServicesListBloc.buildQuery`), so this is the only client-side
  /// filtering layer, applied on top.
  List<ProviderServiceEntity> get filteredServices {
    final categoryId = selectedCategoryId;
    if (categoryId == null) return services;
    return services
        .where((service) => service.category.id == categoryId)
        .toList();
  }

  /// Unique categories represented in the currently-loaded [services],
  /// deduplicated by `category.id` and preserving first-seen order — the
  /// Category filter's option list, per the "derive from the loaded
  /// provider-services response" requirement. Derived from [services], not
  /// [filteredServices], so selecting a category never shrinks the option
  /// list it was chosen from.
  List<CategoryRefEntity> get categoryOptions {
    final seenIds = <String>{};
    final options = <CategoryRefEntity>[];
    for (final service in services) {
      if (seenIds.add(service.category.id)) {
        options.add(service.category);
      }
    }
    return options;
  }

  RequestStatus get status => pagination.status;
  Failure? get failure => pagination.firstPageError;
  int get page => pagination.meta.currentPage;
  int get totalPages => pagination.meta.totalPages;
  bool get loadingMore => pagination.loadingMore;
  bool get isLoading => pagination.isLoadingFirstPage;
  bool get hasError => pagination.hasFirstPageError;
  bool get hasMore => pagination.hasMore;

  ServicesListState copyWith({
    PaginationData<ProviderServiceEntity>? pagination,
    String? searchQuery,
    ProviderServiceStatus? statusFilter,
    String? selectedCategoryId,
    bool clearSelectedCategory = false,
  }) => ServicesListState(
    pagination: pagination ?? this.pagination,
    searchQuery: searchQuery ?? this.searchQuery,
    statusFilter: statusFilter ?? this.statusFilter,
    selectedCategoryId: clearSelectedCategory
        ? null
        : (selectedCategoryId ?? this.selectedCategoryId),
  );

  @override
  List<Object?> get props => [
    pagination,
    searchQuery,
    statusFilter,
    selectedCategoryId,
  ];
}
