import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:services/src/domain/entities/pagination_meta_entity.dart';
import 'package:services/src/domain/entities/service_request_entity.dart';
import 'package:services/src/domain/entities/service_request_status.dart';
import 'package:services/src/domain/repositories/service_requests_repository.dart';

class GetMyServiceRequestsParams extends Equatable {
  const GetMyServiceRequestsParams({
    this.page = 1,
    this.limit = 10,
    this.search,
    this.status,
  });

  final int page;
  final int limit;
  final String? search;
  final ServiceRequestStatus? status;

  @override
  List<Object?> get props => [page, limit, search, status];
}

/// Lists the provider's own service requests (`GET /service-requests`).
class GetMyServiceRequestsUseCase
    implements
        UseCase<
          ServicesPagedResult<ServiceRequestEntity>,
          GetMyServiceRequestsParams
        > {
  const GetMyServiceRequestsUseCase(this._repository);

  final ServiceRequestsRepository _repository;

  @override
  TaskEither<Failure, ServicesPagedResult<ServiceRequestEntity>> call(
    GetMyServiceRequestsParams params,
  ) => _repository.getServiceRequests(
    page: params.page,
    limit: params.limit,
    search: params.search,
    status: params.status,
  );
}
