part of 'request_new_service_bloc.dart';

/// Status of the `GET /categories` fetch backing the category picker
/// (distinct from [RequestStatus], which tracks form submission).
enum RequestNewServiceCategoriesStatus { initial, loading, success, failure }

class RequestNewServiceState extends Equatable {
  const RequestNewServiceState({
    this.status = RequestStatus.initial,
    this.createdRequest,
    this.failure,
    this.categoriesStatus = RequestNewServiceCategoriesStatus.initial,
    this.categories = const [],
    this.categoriesFailure,
  });

  final RequestStatus status;
  final ServiceRequestEntity? createdRequest;
  final Failure? failure;
  final RequestNewServiceCategoriesStatus categoriesStatus;
  final List<CategoryRecordEntity> categories;
  final Failure? categoriesFailure;

  bool get isSubmitting => status == RequestStatus.loading;

  RequestNewServiceState copyWith({
    RequestStatus? status,
    ServiceRequestEntity? createdRequest,
    Failure? failure,
    bool clearFailure = false,
    RequestNewServiceCategoriesStatus? categoriesStatus,
    List<CategoryRecordEntity>? categories,
    Failure? categoriesFailure,
    bool clearCategoriesFailure = false,
  }) => RequestNewServiceState(
    status: status ?? this.status,
    createdRequest: createdRequest ?? this.createdRequest,
    failure: clearFailure ? null : (failure ?? this.failure),
    categoriesStatus: categoriesStatus ?? this.categoriesStatus,
    categories: categories ?? this.categories,
    categoriesFailure: clearCategoriesFailure
        ? null
        : (categoriesFailure ?? this.categoriesFailure),
  );

  @override
  List<Object?> get props => [
    status,
    createdRequest,
    failure,
    categoriesStatus,
    categories,
    categoriesFailure,
  ];
}
