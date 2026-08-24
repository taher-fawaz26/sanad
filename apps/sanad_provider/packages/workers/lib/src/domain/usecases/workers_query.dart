import 'package:core/core.dart';
import 'package:workers/src/domain/entities/worker_status.dart';
import 'package:workers/src/domain/entities/worker_type.dart';

/// `GET /workers` query — `status` (`active`/`inactive`) and `type`
/// (`worker`/`manager`) are real, documented server-side filters (confirmed
/// against the live API contract); `null` omits the param entirely, which
/// the backend treats as "any" — there is no separate "all" value to send.
class WorkersQuery extends PageQuery {
  const WorkersQuery({
    super.page,
    super.limit,
    super.search,
    this.status,
    this.type,
  });

  final WorkerStatus? status;
  final WorkerType? type;

  @override
  WorkersQuery copyWithPage(int page) => WorkersQuery(
    page: page,
    limit: limit,
    search: search,
    status: status,
    type: type,
  );

  @override
  Map<String, dynamic> toQueryMap() => {
    ...super.toQueryMap(),
    if (status != null) 'status': status!.toApiValue(),
    if (type != null) 'type': type!.toApiString(),
  };

  @override
  List<Object?> get props => [...super.props, status, type];
}
