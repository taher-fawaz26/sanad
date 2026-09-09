import 'package:core/core.dart';

/// Query for `GET notifications`.
///
/// `limit` is capped at [kMaxPageLimit] by [PageQuery.toQueryMap]; nothing here
/// needs to restate the cap.
class NotificationsQuery extends PageQuery {
  const NotificationsQuery({super.page, super.limit});

  @override
  NotificationsQuery copyWithPage(int page) =>
      NotificationsQuery(page: page, limit: limit);
}
