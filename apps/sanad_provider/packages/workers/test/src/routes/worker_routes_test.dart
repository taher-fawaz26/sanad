import 'package:flutter_test/flutter_test.dart';
import 'package:workers/src/routes/worker_routes.dart';

void main() {
  group('WorkerRoutes', () {
    test('protectedRoutes contains only list', () {
      expect(WorkerRoutes.protectedRoutes, {WorkerRoutes.list});
    });

    test('isProtectedRoute is true for the list and any nested deep link', () {
      expect(WorkerRoutes.isProtectedRoute(WorkerRoutes.list), isTrue);
      expect(
        WorkerRoutes.isProtectedRoute(WorkerRoutes.detailsFor('w1')),
        isTrue,
      );
      expect(WorkerRoutes.isProtectedRoute(WorkerRoutes.add), isTrue);
    });

    test('isProtectedRoute is false for an unrelated route', () {
      expect(WorkerRoutes.isProtectedRoute('/home'), isFalse);
    });
  });

  group('WorkerRoutes.isOwnerOnlyRoute (RBAC Phase 7E)', () {
    test('add (invite) and an edit are owner-only', () {
      expect(WorkerRoutes.isOwnerOnlyRoute(WorkerRoutes.add), isTrue);
      expect(
        WorkerRoutes.isOwnerOnlyRoute(WorkerRoutes.editWorkerFor('w1')),
        isTrue,
      );
    });

    test('the list and a worker detail are NOT owner-only — '
        'permission-gated instead', () {
      expect(WorkerRoutes.isOwnerOnlyRoute(WorkerRoutes.list), isFalse);
      expect(
        WorkerRoutes.isOwnerOnlyRoute(WorkerRoutes.detailsFor('w1')),
        isFalse,
      );
    });

    test('an unrelated route is not owner-only', () {
      expect(WorkerRoutes.isOwnerOnlyRoute('/home'), isFalse);
    });
  });
}
