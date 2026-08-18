import 'package:flutter_test/flutter_test.dart';
import 'package:network/network.dart';
import 'package:provider_rbac/src/data/models/permission_dto.dart';
import 'package:provider_rbac/src/data/models/role_dto.dart';
import 'package:provider_rbac/src/domain/entities/role_persona_type.dart';

/// Regression tests pinned to the LIVE `Provider RBAC` Swagger response
/// shapes (verified against dev-api.trysanad.us). If the backend changes the
/// envelope or a field, these fail loudly rather than silently mis-parsing.
///
/// `displayNameAr`/`descriptionAr` were removed from these responses in the
/// backend's language-negotiation migration: the language of `displayName`/
/// `description` now depends on the request's `x-lang`/`Accept-Language`
/// header instead of a separate Arabic-suffixed field.
void main() {
  group('GET /provider/roles — PaginatedRolesResponseDto', () {
    // Verbatim shape from the live endpoint.
    final json = <String, dynamic>{
      'data': [
        {
          'id': 'b79039e4-9618-4019-b94e-793545bfe51b',
          'name': 'branch-manager',
          'displayName': 'Branch Manager',
          'description': 'Manage branches and view workers and services',
          'userType': 'worker',
          'isSystem': true,
          'permissions': [
            {
              'id': '5725d361-2e55-4000-a686-188b43cee341',
              'action': 'provider:branch:view',
              'displayName': 'View branches',
              'description': 'View branch lists and details',
              'resource': 'branch',
              'isAdmin': false,
            },
          ],
        },
        {
          'id': '6487cbc1-a66f-4b56-b6ce-38dc48754530',
          'name': 'worker-basic',
          'displayName': 'Worker',
          'description': 'View assigned branches and services',
          'userType': 'worker',
          'isSystem': true,
          'permissions': <dynamic>[],
        },
      ],
      'meta': {
        'totalItems': 2,
        'itemCount': 2,
        'itemsPerPage': 10,
        'totalPages': 1,
        'currentPage': 1,
      },
    };

    test('parsePage unwraps the envelope into items + meta', () {
      final page = parsePage(json, RoleDto.fromJson);
      expect(page.items, hasLength(2));
      expect(page.meta.totalItems, 2);
      expect(page.meta.currentPage, 1);
      expect(page.meta.totalPages, 1);
      expect(page.hasMore, isFalse);
    });

    test('maps role identity, localization, and system flag', () {
      final role = parsePage(json, RoleDto.fromJson).items.first.toEntity();
      expect(role.name, 'branch-manager');
      expect(role.displayName, 'Branch Manager');
      expect(role.userType, RolePersonaType.worker);
      expect(role.isSystem, isTrue);
      expect(role.permissions.single.action, 'provider:branch:view');
      expect(role.permissions.single.resource, 'branch');
    });
  });

  group('GET /provider/permissions — PermissionResponseDto[]', () {
    final json = <Map<String, dynamic>>[
      {
        'id': '0f2eb02d-ec53-469a-9808-9720a0b0f2b4',
        'action': 'provider:branch:create',
        'displayName': 'Create branches',
        'description': 'Create new branches',
        'resource': 'branch',
        'isAdmin': false,
      },
      {
        'id': 'de350937-c14c-4e77-88a8-fbdf0767e549',
        'action': 'provider:worker:view',
        'displayName': 'View workers',
        'description': 'View worker and invitation details',
        'resource': 'worker',
        'isAdmin': false,
      },
    ];

    test('parses the bare array with all contract fields incl. isAdmin', () {
      final permissions = json.map(PermissionDto.fromJson).toList();
      expect(permissions, hasLength(2));
      final first = permissions.first.toEntity();
      expect(first.action, 'provider:branch:create');
      expect(first.resource, 'branch');
      expect(first.isAdmin, isFalse);
    });

    test('groups by resource for the permission editor', () {
      final permissions = json.map(PermissionDto.fromJson).toList();
      final byResource = <String, List<PermissionDto>>{};
      for (final p in permissions) {
        byResource.putIfAbsent(p.resource, () => []).add(p);
      }
      expect(byResource.keys, containsAll(<String>['branch', 'worker']));
    });
  });
}
