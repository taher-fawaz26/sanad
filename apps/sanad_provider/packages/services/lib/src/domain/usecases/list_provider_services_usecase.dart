import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:services/src/domain/entities/pagination_meta_entity.dart';
import 'package:services/src/domain/entities/provider_service_entity.dart';
import 'package:services/src/domain/entities/provider_service_status.dart';
import 'package:services/src/domain/repositories/provider_services_repository.dart';

class ListProviderServicesParams extends Equatable {
  const ListProviderServicesParams({
    this.page = 1,
    this.limit = 10,
    this.search,
    this.status,
  });

  final int page;
  final int limit;
  final String? search;
  final ProviderServiceStatus? status;

  @override
  List<Object?> get props => [page, limit, search, status];
}

class ListProviderServicesUseCase
    implements
        UseCase<
          ServicesPagedResult<ProviderServiceEntity>,
          ListProviderServicesParams
        > {
  const ListProviderServicesUseCase(this._repository);

  final ProviderServicesRepository _repository;

  @override
  TaskEither<Failure, ServicesPagedResult<ProviderServiceEntity>> call(
    ListProviderServicesParams params,
  ) => _repository.listProviderServices(
    page: params.page,
    limit: params.limit,
    search: params.search,
    status: params.status,
  );
}
