import 'package:flutter_test/flutter_test.dart';
import 'package:workers/src/domain/entities/worker_status.dart';
import 'package:workers/src/domain/entities/worker_type.dart';
import 'package:workers/src/domain/usecases/workers_query.dart';

void main() {
  group('WorkersQuery.toQueryMap', () {
    test('omits status/type entirely when unset — only supported Swagger '
        'params (page/limit/search) are ever sent', () {
      const query = WorkersQuery(page: 2, search: 'ali');

      final map = query.toQueryMap();

      expect(map, {'page': 2, 'limit': 20, 'search': 'ali'});
      expect(map.containsKey('status'), isFalse);
      expect(map.containsKey('type'), isFalse);
    });

    test('serializes status as its raw API value when set', () {
      const query = WorkersQuery(status: WorkerStatus.active);

      expect(query.toQueryMap()['status'], 'active');
    });

    test('serializes an inactive status filter', () {
      const query = WorkersQuery(status: WorkerStatus.inactive);

      expect(query.toQueryMap()['status'], 'inactive');
    });

    test('serializes type as its raw API value when set', () {
      const query = WorkersQuery(type: WorkerType.manager);

      expect(query.toQueryMap()['type'], 'manager');
    });

    test('serializes a worker type filter', () {
      const query = WorkersQuery(type: WorkerType.worker);

      expect(query.toQueryMap()['type'], 'worker');
    });

    test('serializes status and type together', () {
      const query = WorkersQuery(
        status: WorkerStatus.active,
        type: WorkerType.manager,
      );

      final map = query.toQueryMap();
      expect(map['status'], 'active');
      expect(map['type'], 'manager');
    });

    test('copyWithPage preserves status and type', () {
      const query = WorkersQuery(
        status: WorkerStatus.inactive,
        type: WorkerType.worker,
      );

      final next = query.copyWithPage(3);

      expect(next.page, 3);
      expect(next.status, WorkerStatus.inactive);
      expect(next.type, WorkerType.worker);
    });

    test('equality includes status and type', () {
      expect(
        const WorkersQuery(status: WorkerStatus.active),
        const WorkersQuery(status: WorkerStatus.active),
      );
      expect(
        const WorkersQuery(status: WorkerStatus.active),
        isNot(const WorkersQuery(status: WorkerStatus.inactive)),
      );
      expect(
        const WorkersQuery(),
        isNot(const WorkersQuery(status: WorkerStatus.active)),
      );
    });
  });
}
