import 'package:flutter_test/flutter_test.dart';
import 'package:provider_rbac/src/routes/provider_rbac_routes.dart';

void main() {
  group('ProviderRbacRoutes', () {
    test('protectedRoutes contains list and add', () {
      expect(ProviderRbacRoutes.protectedRoutes, {
        ProviderRbacRoutes.list,
        ProviderRbacRoutes.add,
      });
    });

    test('isProtectedRoute matches list, add, and edit deep links', () {
      expect(
        ProviderRbacRoutes.isProtectedRoute(ProviderRbacRoutes.list),
        isTrue,
      );
      expect(
        ProviderRbacRoutes.isProtectedRoute(ProviderRbacRoutes.add),
        isTrue,
      );
      expect(
        ProviderRbacRoutes.isProtectedRoute(ProviderRbacRoutes.editFor('r1')),
        isTrue,
      );
    });

    test('isProtectedRoute is false for an unrelated route', () {
      expect(ProviderRbacRoutes.isProtectedRoute('/home'), isFalse);
    });
  });
}
