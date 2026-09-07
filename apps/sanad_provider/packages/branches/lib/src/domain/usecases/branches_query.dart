import 'package:branches/src/domain/entities/branch_filter.dart';
import 'package:core/core.dart';

/// `GET /branches` query. Supports server-side search and an optional
/// status filter mapped from the UI [BranchFilter] enum.
///
/// Backend behavior: when `search` is null/empty it is omitted entirely
/// (see [PageQuery.toQueryMap]). `filter` maps to a `status` query param
/// (`ACTIVE` / `MAINTENANCE`); `BranchFilter.all` omits the param.
class BranchesQuery extends PageQuery {
  const BranchesQuery({
    super.page,
    super.limit,
    super.search,
    this.filter = BranchFilter.all,
  });

  final BranchFilter filter;

  @override
  BranchesQuery copyWithPage(int page) => BranchesQuery(
    page: page,
    limit: limit,
    search: search,
    filter: filter,
  );

  @override
  Map<String, dynamic> toQueryMap() => {
    ...super.toQueryMap(),
    if (filter == BranchFilter.active) 'status': 'ACTIVE',
    if (filter == BranchFilter.maintenance) 'status': 'MAINTENANCE',
  };

  @override
  List<Object?> get props => [...super.props, filter];
}
