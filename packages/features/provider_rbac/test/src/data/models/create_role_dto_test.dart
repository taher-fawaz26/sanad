import 'package:flutter_test/flutter_test.dart';
import 'package:provider_rbac/src/data/models/create_role_dto.dart';
import 'package:provider_rbac/src/data/models/update_role_dto.dart';

void main() {
  group('CreateRoleDto.toJson', () {
    test('includes required fields and omits absent optional fields', () {
      const dto = CreateRoleDto(
        name: 'senior-branch-manager',
        displayName: 'Senior Branch Manager',
        permissionIds: ['perm_1', 'perm_2'],
      );
      final json = dto.toJson();
      expect(json['name'], 'senior-branch-manager');
      expect(json['displayName'], 'Senior Branch Manager');
      expect(json['permissionIds'], ['perm_1', 'perm_2']);
      expect(json.containsKey('displayNameAr'), isFalse);
      expect(json.containsKey('description'), isFalse);
      expect(json.containsKey('descriptionAr'), isFalse);
    });

    test('includes optional fields when provided', () {
      const dto = CreateRoleDto(
        name: 'x',
        displayName: 'X',
        displayNameAr: 'س',
        description: 'desc',
        descriptionAr: 'وصف',
        permissionIds: ['perm_1'],
      );
      final json = dto.toJson();
      expect(json['displayNameAr'], 'س');
      expect(json['description'], 'desc');
      expect(json['descriptionAr'], 'وصف');
    });
  });

  group('UpdateRoleDto.toJson', () {
    test('emits an empty map when nothing is set (fully optional)', () {
      const dto = UpdateRoleDto();
      expect(dto.toJson(), isEmpty);
    });

    test('includes only the fields that were set', () {
      const dto = UpdateRoleDto(
        displayName: 'New Name',
        permissionIds: ['perm_9'],
      );
      final json = dto.toJson();
      expect(json, {
        'displayName': 'New Name',
        'permissionIds': ['perm_9'],
      });
    });
  });
}
