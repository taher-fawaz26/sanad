import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:services/src/domain/entities/pagination_meta_entity.dart';
import 'package:services/src/domain/entities/service_record_entity.dart';
import 'package:services/src/domain/repositories/services_repository.dart';

class GetServicesListParams extends Equatable {
  const GetServicesListParams({
    this.page = 1,
    this.limit = 10,
    this.search,
    this.categoryId,
    this.isActive,
  });

  final int page;
  final int limit;
  final String? search;
  final String? categoryId;
  final bool? isActive;

  @override
  List<Object?> get props => [page, limit, search, categoryId, isActive];
}

class GetServicesListUseCase
    implements
        UseCase<
          ServicesPagedResult<ServiceRecordEntity>,
          GetServicesListParams
        > {
  const GetServicesListUseCase(this._repository);

  final ServicesRepository _repository;

  @override
  TaskEither<Failure, ServicesPagedResult<ServiceRecordEntity>> call(
    GetServicesListParams params,
  ) => _repository.getServices(
    page: params.page,
    limit: params.limit,
    search: params.search,
    categoryId: params.categoryId,
    isActive: params.isActive,
  );
}
