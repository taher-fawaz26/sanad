import 'package:flutter_test/flutter_test.dart';
import 'package:provider_rbac/src/data/endpoints/provider_rbac_api_paths.dart';

/// Pins the RBAC endpoint paths. They MUST be relative (no leading `/api/v1`)
/// — the API client's base URL already ends in `/api/v1`, so an absolute path
/// doubles the prefix and 404s (`/api/v1/api/v1/provider/roles`).
void main() {
  group('ProviderRbacApiPaths — relative, matching live Swagger', () {
    test('role + permission paths', () {
      expect(ProviderRbacApiPaths.roles, 'provider/roles');
      expect(ProviderRbacApiPaths.permissions, 'provider/permissions');
      expect(ProviderRbacApiPaths.role('r1'), 'provider/roles/r1');
    });

    test('worker-role assignment paths', () {
      expect(ProviderRbacApiPaths.workerRoles('w1'), 'workers/w1/roles');
      expect(
        ProviderRbacApiPaths.workerRole('w1', 'r1'),
        'workers/w1/roles/r1',
      );
    });

    test('no path carries a leading slash or /api/v1 prefix', () {
      final paths = <String>[
        ProviderRbacApiPaths.roles,
        ProviderRbacApiPaths.permissions,
        ProviderRbacApiPaths.role('r1'),
        ProviderRbacApiPaths.workerRoles('w1'),
        ProviderRbacApiPaths.workerRole('w1', 'r1'),
      ];
      for (final p in paths) {
        expect(p.startsWith('/'), isFalse, reason: '$p must be relative');
        expect(p.contains('api/v1'), isFalse, reason: '$p must omit api/v1');
      }
    });
  });
}
