import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:workers/src/domain/entities/paged_result.dart';
import 'package:workers/src/domain/entities/worker_entity.dart';
import 'package:workers/src/domain/repositories/worker_repository.dart';

class GetWorkersParams extends Equatable {
  const GetWorkersParams({this.page = 1, this.limit = 20, this.search});

  final int page;
  final int limit;
  final String? search;

  @override
  List<Object?> get props => [page, limit, search];
}

class GetWorkersUseCase
    implements UseCase<PagedResult<WorkerEntity>, GetWorkersParams> {
  const GetWorkersUseCase(this._repository);

  final WorkerRepository _repository;

  @override
  TaskEither<Failure, PagedResult<WorkerEntity>> call(
    GetWorkersParams params,
  ) => _repository.getWorkers(
    page: params.page,
    limit: params.limit,
    search: params.search,
  );
}
