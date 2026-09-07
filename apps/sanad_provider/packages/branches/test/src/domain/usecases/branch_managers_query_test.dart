import 'package:branches/src/domain/usecases/branch_managers_query.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BranchManagersQuery', () {
    test('always sends type=manager', () {
      expect(const BranchManagersQuery().toQueryMap()['type'], 'manager');
    });

    test('includes page/limit and omits blank search', () {
      final map = const BranchManagersQuery(page: 2, limit: 20).toQueryMap();
      expect(map['page'], 2);
      expect(map['limit'], 20);
      expect(map.containsKey('search'), isFalse);
    });

    test('includes a non-empty trimmed search term', () {
      final map = const BranchManagersQuery(search: '  ali  ').toQueryMap();
      expect(map['search'], 'ali');
      expect(map['type'], 'manager');
    });

    test('copyWithPage preserves search + type', () {
      final q = const BranchManagersQuery(search: 'x').copyWithPage(3);
      expect(q.page, 3);
      expect(q.search, 'x');
      expect(q.toQueryMap()['type'], 'manager');
    });

    test('extends PageQuery with the default page limit', () {
      expect(const BranchManagersQuery().limit, kDefaultPageLimit);
    });
  });
}
