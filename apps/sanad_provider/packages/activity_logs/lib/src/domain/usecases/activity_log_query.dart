import 'package:activity_logs/src/domain/entities/activity_action.dart';
import 'package:activity_logs/src/domain/entities/activity_subject.dart';
import 'package:core/core.dart';

/// `GET /activity-logs` query.
///
/// Supports every documented backend filter — [actorId], repeatable
/// [actions], [subjectType], [subjectId], and a [from]/[to] date range —
/// even though the Worker Details "Recent Activity" section only sets
/// [actorId]/[limit] today, so a future filtered/paginated screen can reuse
/// this query unchanged. There is no `search` param on this endpoint.
class ActivityLogQuery extends PageQuery {
  const ActivityLogQuery({
    super.page,
    super.limit,
    this.actorId,
    this.actions,
    this.subjectType,
    this.subjectId,
    this.from,
    this.to,
  });

  final String? actorId;
  final List<ActivityAction>? actions;
  final ActivitySubjectType? subjectType;
  final String? subjectId;
  final DateTime? from;
  final DateTime? to;

  @override
  ActivityLogQuery copyWithPage(int page) => ActivityLogQuery(
    page: page,
    limit: limit,
    actorId: actorId,
    actions: actions,
    subjectType: subjectType,
    subjectId: subjectId,
    from: from,
    to: to,
  );

  @override
  Map<String, dynamic> toQueryMap() => {
    'page': page,
    'limit': limit,
    if (actorId != null) 'actorId': actorId,
    if (actions != null && actions!.isNotEmpty)
      'action': actions!.map((action) => action.name).join(','),
    if (subjectType != null) 'subjectType': subjectType!.name,
    if (subjectId != null) 'subjectId': subjectId,
    if (from != null) 'from': from!.toUtc().toIso8601String(),
    if (to != null) 'to': to!.toUtc().toIso8601String(),
  };

  @override
  List<Object?> get props => [
    page,
    limit,
    actorId,
    actions,
    subjectType,
    subjectId,
    from,
    to,
  ];
}
