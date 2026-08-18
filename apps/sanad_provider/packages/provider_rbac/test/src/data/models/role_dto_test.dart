import 'package:flutter_test/flutter_test.dart';
import 'package:provider_rbac/src/data/models/role_dto.dart';
import 'package:provider_rbac/src/domain/entities/role_persona_type.dart';

void main() {
  Map<String, dynamic> roleJson() => {
    'id': 'role_1',
    'name': 'branch-manager',
    'displayName': 'Branch Manager',
    'description': 'Manages a branch',
    'userType': 'companyProvider',
    'isSystem': true,
    'permissions': [
      {
        'id': 'perm_1',
        'action': 'branch:create',
        'displayName': 'Create branch',
        'resource': 'branch',
      },
    ],
  };

  group('RoleDto.fromJson', () {
    test('maps every field, including nested permissions', () {
      final dto = RoleDto.fromJson(roleJson());
      expect(dto.id, 'role_1');
      expect(dto.name, 'branch-manager');
      expect(dto.displayName, 'Branch Manager');
      expect(dto.description, 'Manages a branch');
      expect(dto.userType, RolePersonaType.companyProvider);
      expect(dto.isSystem, isTrue);
      expect(dto.permissions, hasLength(1));
      expect(dto.permissions.single.action, 'branch:create');
    });

    test('defaults permissions to empty list when absent', () {
      final json = roleJson()..remove('permissions');
      final dto = RoleDto.fromJson(json);
      expect(dto.permissions, isEmpty);
    });

    test('toEntity() rebuilds the full entity graph', () {
      final entity = RoleDto.fromJson(roleJson()).toEntity();
      expect(entity.id, 'role_1');
      expect(entity.permissions.single.id, 'perm_1');
      expect(entity.userType, RolePersonaType.companyProvider);
    });
  });

  group('RolePersonaType.fromApi', () {
    test('parses every documented value', () {
      expect(RolePersonaType.fromApi('admin'), RolePersonaType.admin);
      expect(RolePersonaType.fromApi('client'), RolePersonaType.client);
      expect(
        RolePersonaType.fromApi('individualProvider'),
        RolePersonaType.individualProvider,
      );
      expect(
        RolePersonaType.fromApi('companyProvider'),
        RolePersonaType.companyProvider,
      );
      expect(RolePersonaType.fromApi('worker'), RolePersonaType.worker);
    });

    test('toApi round-trips every value', () {
      for (final value in RolePersonaType.values) {
        expect(RolePersonaType.fromApi(value.toApi()), value);
      }
    });
  });
}
