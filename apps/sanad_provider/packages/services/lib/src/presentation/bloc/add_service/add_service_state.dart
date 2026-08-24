part of 'add_service_bloc.dart';

/// Status of the `GET /categories` fetch backing the category picker
/// (distinct from [RequestStatus], which tracks form submission).
enum AddServiceCategoriesStatus { initial, loading, success, failure }

/// Status of the category-scoped `GET /services?categoryId=` catalog fetch
/// backing the service picker (distinct from [RequestStatus], which tracks
/// form submission).
enum AddServiceCatalogStatus { initial, loading, success, failure }

class AddServiceState extends Equatable {
  const AddServiceState({
    this.status = RequestStatus.initial,
    this.createdService,
    this.failure,
    this.categoriesStatus = AddServiceCategoriesStatus.initial,
    this.categories = const [],
    this.categoriesFailure,
    this.catalogStatus = AddServiceCatalogStatus.initial,
    this.catalogItems = const [],
    this.catalogFailure,
  });

  final RequestStatus status;
  final ProviderServiceEntity? createdService;
  final Failure? failure;
  final AddServiceCategoriesStatus categoriesStatus;
  final List<CategoryRecordEntity> categories;
  final Failure? categoriesFailure;
  final AddServiceCatalogStatus catalogStatus;
  final List<CatalogServiceEntity> catalogItems;
  final Failure? catalogFailure;

  bool get isSubmitting => status == RequestStatus.loading;

  AddServiceState copyWith({
    RequestStatus? status,
    ProviderServiceEntity? createdService,
    Failure? failure,
    bool clearFailure = false,
    AddServiceCategoriesStatus? categoriesStatus,
    List<CategoryRecordEntity>? categories,
    Failure? categoriesFailure,
    bool clearCategoriesFailure = false,
    AddServiceCatalogStatus? catalogStatus,
    List<CatalogServiceEntity>? catalogItems,
    Failure? catalogFailure,
    bool clearCatalogFailure = false,
  }) => AddServiceState(
    status: status ?? this.status,
    createdService: createdService ?? this.createdService,
    failure: clearFailure ? null : (failure ?? this.failure),
    categoriesStatus: categoriesStatus ?? this.categoriesStatus,
    categories: categories ?? this.categories,
    categoriesFailure: clearCategoriesFailure
        ? null
        : (categoriesFailure ?? this.categoriesFailure),
    catalogStatus: catalogStatus ?? this.catalogStatus,
    catalogItems: catalogItems ?? this.catalogItems,
    catalogFailure: clearCatalogFailure
        ? null
        : (catalogFailure ?? this.catalogFailure),
  );

  @override
  List<Object?> get props => [
    status,
    createdService,
    failure,
    categoriesStatus,
    categories,
    categoriesFailure,
    catalogStatus,
    catalogItems,
    catalogFailure,
  ];
}
