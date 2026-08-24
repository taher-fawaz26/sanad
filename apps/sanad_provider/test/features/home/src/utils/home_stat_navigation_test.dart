import 'package:branches/branches.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_provider/src/features/home/src/utils/home_stat_navigation.dart';
import 'package:workers/workers.dart';

void main() {
  group('statRouteForKey', () {
    test('resolves branches to the branches list route', () {
      expect(statRouteForKey('branches'), BranchRoutes.list);
    });

    test('resolves workers to the workers list route', () {
      expect(statRouteForKey('workers'), WorkerRoutes.list);
    });

    test('resolves a covered-areas key to the branch coverage route', () {
      expect(statRouteForKey('coveredAreas'), BranchRoutes.coverage);
    });

    test('returns null for an unrecognized key', () {
      expect(statRouteForKey('totalRequests'), isNull);
      expect(statRouteForKey('somethingNew'), isNull);
    });
  });
}
