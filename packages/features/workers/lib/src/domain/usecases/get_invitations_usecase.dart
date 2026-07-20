import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:workers/src/domain/entities/invitation_entity.dart';
import 'package:workers/src/domain/entities/paged_result.dart';
import 'package:workers/src/domain/repositories/worker_repository.dart';

class GetInvitationsParams extends Equatable {
  const GetInvitationsParams({this.page = 1, this.limit = 20, this.search});

  final int page;
  final int limit;
  final String? search;

  @override
  List<Object?> get props => [page, limit, search];
}

class GetInvitationsUseCase
    implements UseCase<PagedResult<InvitationEntity>, GetInvitationsParams> {
  const GetInvitationsUseCase(this._repository);

  final WorkerRepository _repository;

  @override
  TaskEither<Failure, PagedResult<InvitationEntity>> call(
    GetInvitationsParams params,
  ) => _repository.getInvitations(
    page: params.page,
    limit: params.limit,
    search: params.search,
  );
}
