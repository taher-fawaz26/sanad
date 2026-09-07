import 'package:activity_logs/src/domain/entities/activity_action.dart';
import 'package:activity_logs/src/domain/entities/activity_subject.dart';
import 'package:activity_logs/src/domain/usecases/activity_log_query.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ActivityLogQuery.toQueryMap', () {
    test(
      'page/limit only when no filters are set — and never sends `lang`',
      () {
        const query = ActivityLogQuery(page: 2, limit: 10);

        final map = query.toQueryMap();

        expect(map, {'page': 2, 'limit': 10});
        expect(map.containsKey('lang'), isFalse);
        expect(map.containsKey('search'), isFalse);
      },
    );

    test('serializes actorId when set', () {
      const query = ActivityLogQuery(actorId: 'w-1');
      expect(query.toQueryMap()['actorId'], 'w-1');
    });

    test('serializes a single action', () {
      const query = ActivityLogQuery(actions: [ActivityAction.branchCreated]);
      expect(query.toQueryMap()['action'], 'branchCreated');
    });

    test('serializes repeatable actions as a comma-joined list', () {
      const query = ActivityLogQuery(
        actions: [ActivityAction.branchCreated, ActivityAction.branchDeleted],
      );
      expect(query.toQueryMap()['action'], 'branchCreated,branchDeleted');
    });

    test('omits action key when actions is empty', () {
      const query = ActivityLogQuery(actions: []);
      expect(query.toQueryMap().containsKey('action'), isFalse);
    });

    test('serializes subjectType and subjectId', () {
      const query = ActivityLogQuery(
        subjectType: ActivitySubjectType.branch,
        subjectId: 'br-1',
      );
      final map = query.toQueryMap();
      expect(map['subjectType'], 'branch');
      expect(map['subjectId'], 'br-1');
    });

    test('serializes from/to as UTC ISO 8601', () {
      final query = ActivityLogQuery(
        from: DateTime.utc(2026, 8),
        to: DateTime.utc(2026, 8, 31, 23, 59, 59),
      );
      final map = query.toQueryMap();
      expect(map['from'], '2026-08-01T00:00:00.000Z');
      expect(map['to'], '2026-08-31T23:59:59.000Z');
    });

    test('copyWithPage preserves every other field', () {
      const query = ActivityLogQuery(
        actorId: 'w-1',
        actions: [ActivityAction.branchCreated],
        subjectType: ActivitySubjectType.branch,
        subjectId: 'br-1',
      );

      final next = query.copyWithPage(3);

      expect(next.page, 3);
      expect(next.actorId, 'w-1');
      expect(next.actions, [ActivityAction.branchCreated]);
      expect(next.subjectType, ActivitySubjectType.branch);
      expect(next.subjectId, 'br-1');
    });

    test('equality includes every filter field', () {
      expect(
        const ActivityLogQuery(actorId: 'w-1'),
        const ActivityLogQuery(actorId: 'w-1'),
      );
      expect(
        const ActivityLogQuery(actorId: 'w-1'),
        isNot(const ActivityLogQuery(actorId: 'w-2')),
      );
    });
  });
}
