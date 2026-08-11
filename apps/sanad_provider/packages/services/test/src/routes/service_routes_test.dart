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
}
