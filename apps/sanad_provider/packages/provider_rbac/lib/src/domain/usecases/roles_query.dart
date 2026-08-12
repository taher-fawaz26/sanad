import 'package:core/core.dart';

/// Query for `GET /api/v1/provider/roles` — the endpoint supports `page`,
/// `limit`, and `search` (1–100 chars), per the live Swagger contract.
class RolesQuery extends PageQuery {
  const RolesQuery({super.page, super.limit, super.search});

  @override
  RolesQuery copyWithPage(int page) =>
      RolesQuery(page: page, limit: limit, search: search);
}
