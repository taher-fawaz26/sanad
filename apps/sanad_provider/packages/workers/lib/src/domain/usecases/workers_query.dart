import 'package:core/core.dart';

class WorkersQuery extends PageQuery {
  const WorkersQuery({super.page, super.limit, super.search});

  @override
  WorkersQuery copyWithPage(int page) =>
      WorkersQuery(page: page, limit: limit, search: search);
}
