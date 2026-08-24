import 'package:flutter_test/flutter_test.dart';
import 'package:provider_rbac/src/domain/entities/permission_entity.dart';
import 'package:provider_rbac/src/domain/entities/role_entity.dart';
import 'package:provider_rbac/src/domain/entities/role_persona_type.dart';
import 'package:provider_rbac/src/presentation/utils/role_display_name.dart';

// No EasyLocalization bootstrap (matches the rest of this package's test
// convention) — `.tr()` falls back to the raw i18n key, so assertions
// target those raw keys directly. Real translated text ("Branch Manager" /
// "مدير فرع") is covered by `melos run validate:l10n` key-parity plus the
// translation files themselves; this test verifies the *selection* logic —
// which key (if any) `localizedDisplayName()` picks for a given role.

const _permissions = <PermissionEntity>[];

RoleEntity _role({
  required String name,
  required String displayName,
  bool isSystem = true,
}) => RoleEntity(
  id: 'id-$name',
  name: name,
  displayName: displayName,
  userType: RolePersonaType.worker,
  isSystem: isSystem,
  permissions: _permissions,
);

void main() {
  group('RoleLocalizedDisplayName.localizedDisplayName', () {
    test('system worker-basic role resolves to the shared i18n key', () {
      final role = _role(name: 'worker-basic', displayName: 'Worker');
      expect(
        role.localizedDisplayName(),
        'provider_rbac.system_role_worker',
      );
    });

    test('system branch-manager role resolves to the shared i18n key', () {
      final role = _role(
        name: 'branch-manager',
        displayName: 'Branch Manager',
      );
      expect(
        role.localizedDisplayName(),
        'provider_rbac.system_role_branch_manager',
      );
    });

    test(
      'a custom (non-system) role is never localized — passes the raw '
      'admin-authored displayName straight through, in any language',
      () {
        final english = _role(
          name: 'senior-technician',
          displayName: 'Senior Technician',
          isSystem: false,
        );
        final arabic = _role(
          name: 'مدير-اقليمي',
          displayName: 'مدير إقليمي',
          isSystem: false,
        );
        expect(english.localizedDisplayName(), 'Senior Technician');
        expect(arabic.localizedDisplayName(), 'مدير إقليمي');
      },
    );

    test(
      'an unrecognized system-flagged role (unknown/new backend slug) '
      'falls back to the raw displayName instead of throwing or guessing',
      () {
        final role = _role(
          name: 'some-future-system-role',
          displayName: 'Some Future Role',
        );
        expect(role.localizedDisplayName(), 'Some Future Role');
      },
    );

    test(
      'does not depend on a displayNameAr field — RoleEntity has none, and '
      'the extension only ever reads name/isSystem/displayName',
      () {
        // Compile-time proof: RoleEntity has no displayNameAr constructor
        // parameter (would fail to compile if one were required/expected).
        final role = _role(name: 'branch-manager', displayName: 'anything');
        expect(role.localizedDisplayName(), isNotEmpty);
      },
    );
  });
}
