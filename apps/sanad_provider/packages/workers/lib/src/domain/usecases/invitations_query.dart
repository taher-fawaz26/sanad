import 'package:core/core.dart';

class InvitationsQuery extends PageQuery {
  const InvitationsQuery({super.page, super.limit, super.search});

  @override
  InvitationsQuery copyWithPage(int page) =>
      InvitationsQuery(page: page, limit: limit, search: search);
}
