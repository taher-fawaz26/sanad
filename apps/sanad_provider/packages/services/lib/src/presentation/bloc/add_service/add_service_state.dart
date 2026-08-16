part of 'add_service_bloc.dart';

/// Status of the `GET /services` catalog fetch backing the service-name
/// picker (distinct from [RequestStatus], which tracks form submission).
enum AddServiceCatalogStatus { initial, loading, success, failure }

class AddServiceState extends Equatable {
  const AddServiceState({
    this.status = RequestStatus.initial,
    this.createdService,
    this.failure,
    this.catalogStatus = AddServiceCatalogStatus.initial,
    this.catalogItems = const [],
    this.catalogFailure,
  });

  final RequestStatus status;
  final ProviderServiceEntity? createdService;
  final Failure? failure;
  final AddServiceCatalogStatus catalogStatus;
  final List<CatalogServiceEntity> catalogItems;
  final Failure? catalogFailure;

  bool get isSubmitting => status == RequestStatus.loading;

  AddServiceState copyWith({
    RequestStatus? status,
    ProviderServiceEntity? createdService,
    Failure? failure,
    bool clearFailure = false,
    AddServiceCatalogStatus? catalogStatus,
    List<CatalogServiceEntity>? catalogItems,
    Failure? catalogFailure,
    bool clearCatalogFailure = false,
  }) => AddServiceState(
    status: status ?? this.status,
    createdService: createdService ?? this.createdService,
    failure: clearFailure ? null : (failure ?? this.failure),
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
    catalogStatus,
    catalogItems,
    catalogFailure,
  ];
}
