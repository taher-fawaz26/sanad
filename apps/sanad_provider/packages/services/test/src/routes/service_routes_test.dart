import 'package:flutter_test/flutter_test.dart';
import 'package:services/src/routes/service_routes.dart';

void main() {
  group('ServiceRoutes', () {
    test('protectedRoutes contains list, add, and requestNew', () {
      expect(ServiceRoutes.protectedRoutes, {
        ServiceRoutes.list,
        ServiceRoutes.add,
        ServiceRoutes.requestNew,
      });
    });

    test('isProtectedRoute is true for all three routes', () {
      expect(ServiceRoutes.isProtectedRoute(ServiceRoutes.list), isTrue);
      expect(ServiceRoutes.isProtectedRoute(ServiceRoutes.add), isTrue);
      expect(ServiceRoutes.isProtectedRoute(ServiceRoutes.requestNew), isTrue);
    });

    test('isProtectedRoute is false for an unrelated route', () {
      expect(ServiceRoutes.isProtectedRoute('/home'), isFalse);
    });
  });

  group('ServiceRoutes.isOwnerOnlyRoute (RBAC Phase 7E)', () {
    test('add, request-new, a request detail, and an edit are owner-only', () {
      expect(ServiceRoutes.isOwnerOnlyRoute(ServiceRoutes.add), isTrue);
      expect(ServiceRoutes.isOwnerOnlyRoute(ServiceRoutes.requestNew), isTrue);
      expect(
        ServiceRoutes.isOwnerOnlyRoute(ServiceRoutes.requestDetailsFor('r1')),
        isTrue,
      );
      expect(
        ServiceRoutes.isOwnerOnlyRoute(ServiceRoutes.editFor('svc-1')),
        isTrue,
      );
    });

    test('the list and a service detail are NOT owner-only — '
        'permission-gated instead', () {
      expect(ServiceRoutes.isOwnerOnlyRoute(ServiceRoutes.list), isFalse);
      expect(
        ServiceRoutes.isOwnerOnlyRoute(ServiceRoutes.detailsFor('svc-1')),
        isFalse,
      );
    });

    test('an unrelated route is not owner-only', () {
      expect(ServiceRoutes.isOwnerOnlyRoute('/home'), isFalse);
    });
  });
}
