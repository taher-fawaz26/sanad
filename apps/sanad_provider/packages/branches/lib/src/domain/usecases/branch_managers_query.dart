import 'package:core/core.dart';

/// `GET /branches/managers` query. The `type=manager` param the backend
/// requires is folded into [toQueryMap] so callers only pass paging + search.
class BranchManagersQuery extends PageQuery {
  const BranchManagersQuery({super.page, super.limit, super.search});

  @override
  BranchManagersQuery copyWithPage(int page) =>
      BranchManagersQuery(page: page, limit: limit, search: search);

  @override
  Map<String, dynamic> toQueryMap() => {
    ...super.toQueryMap(),
    'type': 'manager',
  };
}
