import 'package:flutter_test/flutter_test.dart';
import 'package:provider_rbac/src/domain/entities/role_entity.dart';
import 'package:provider_rbac/src/domain/entities/role_persona_type.dart';
import 'package:provider_rbac/src/domain/policies/role_assignment_policy.dart';
import 'package:workers/src/domain/entities/worker_type.dart';

RoleEntity _role({
  required String id,
  required String name,
  required bool isSystem,
  String? displayName,
}) => RoleEntity(
  id: id,
  name: name,
  displayName: displayName ?? name,
  userType: RolePersonaType.worker,
  isSystem: isSystem,
  permissions: const [],
);

void main() {
  final workerBasic = _role(id: 'w1', name: 'worker-basic', isSystem: true);
  final branchManager = _role(
    id: 'm1',
    name: 'branch-manager',
    isSystem: true,
  );
  final projectManager = _role(
    id: 'c1',
    name: 'project-manager',
    isSystem: false,
  );
  final senior = _role(id: 'c2', name: 'senior', isSystem: false);
  final catalog = [workerBasic, branchManager, projectManager, senior];

  group('baselineSlugFor', () {
    test('worker maps to worker-basic', () {
      expect(
        RoleAssignmentPolicy.baselineSlugFor(WorkerType.worker),
        'worker-basic',
      );
    });

    test('manager maps to branch-manager', () {
      expect(
        RoleAssignmentPolicy.baselineSlugFor(WorkerType.manager),
        'branch-manager',
      );
    });
  });

  group('requiredRoleFor', () {
    test('resolves worker-basic for Worker from the catalog', () {
      expect(
        RoleAssignmentPolicy.requiredRoleFor(WorkerType.worker, catalog),
        workerBasic,
      );
    });

    test('resolves branch-manager for Manager from the catalog', () {
      expect(
        RoleAssignmentPolicy.requiredRoleFor(WorkerType.manager, catalog),
        branchManager,
      );
    });

    test('returns null when the baseline slug is absent (backend gap)', () {
      final incompleteCatalog = [projectManager, senior];
      expect(
        RoleAssignmentPolicy.requiredRoleFor(
          WorkerType.worker,
          incompleteCatalog,
        ),
        isNull,
      );
    });

    test('ignores a custom role that happens to share the baseline name', () {
      final impostor = _role(
        id: 'x1',
        name: 'worker-basic',
        isSystem: false,
      );
      expect(
        RoleAssignmentPolicy.requiredRoleFor(WorkerType.worker, [impostor]),
        isNull,
      );
    });
  });

  group('isMandatory / canRemove', () {
    test('the baseline role is mandatory and not removable for its type', () {
      expect(
        RoleAssignmentPolicy.isMandatory(workerBasic, WorkerType.worker),
        isTrue,
      );
      expect(
        RoleAssignmentPolicy.canRemove(workerBasic, WorkerType.worker),
        isFalse,
      );
    });

    test('branch-manager is mandatory and not removable for Manager', () {
      expect(
        RoleAssignmentPolicy.isMandatory(branchManager, WorkerType.manager),
        isTrue,
      );
      expect(
        RoleAssignmentPolicy.canRemove(branchManager, WorkerType.manager),
        isFalse,
      );
    });

    test('the other type baseline is not mandatory for this type', () {
      expect(
        RoleAssignmentPolicy.isMandatory(branchManager, WorkerType.worker),
        isFalse,
      );
      expect(
        RoleAssignmentPolicy.canRemove(branchManager, WorkerType.worker),
        isTrue,
      );
    });

    test('custom roles are always removable', () {
      expect(
        RoleAssignmentPolicy.canRemove(projectManager, WorkerType.worker),
        isTrue,
      );
      expect(
        RoleAssignmentPolicy.canRemove(projectManager, WorkerType.manager),
        isTrue,
      );
    });
  });

  group('assignableAdditionalRoles', () {
    test('Worker has no additional roles to assign', () {
      expect(
        RoleAssignmentPolicy.assignableAdditionalRoles(
          WorkerType.worker,
          catalog,
        ),
        isEmpty,
      );
    });

    test(
      'Manager may assign custom roles only, excluding every system role',
      () {
        final additional = RoleAssignmentPolicy.assignableAdditionalRoles(
          WorkerType.manager,
          catalog,
        );
        expect(additional, containsAll([projectManager, senior]));
        expect(additional, isNot(contains(workerBasic)));
        expect(additional, isNot(contains(branchManager)));
      },
    );
  });

  group('normalizeAfterTypeChange', () {
    test('Worker result is exactly [worker-basic], custom roles dropped', () {
      final selected = [workerBasic, projectManager, senior];
      final normalized = RoleAssignmentPolicy.normalizeAfterTypeChange(
        WorkerType.worker,
        selected,
        catalog,
      );
      expect(normalized, [workerBasic]);
    });

    test('Worker cannot receive the manager system role', () {
      final selected = [branchManager];
      final normalized = RoleAssignmentPolicy.normalizeAfterTypeChange(
        WorkerType.worker,
        selected,
        catalog,
      );
      expect(normalized, [workerBasic]);
      expect(normalized, isNot(contains(branchManager)));
    });

    test('Manager -> keeps custom roles and swaps in branch-manager', () {
      final selected = [branchManager, projectManager];
      final normalized = RoleAssignmentPolicy.normalizeAfterTypeChange(
        WorkerType.manager,
        selected,
        catalog,
      );
      expect(normalized, containsAll([branchManager, projectManager]));
      expect(normalized.length, 2);
    });

    test('Manager excludes worker-basic even if it was selected', () {
      final selected = [workerBasic, branchManager, projectManager];
      final normalized = RoleAssignmentPolicy.normalizeAfterTypeChange(
        WorkerType.manager,
        selected,
        catalog,
      );
      expect(normalized, isNot(contains(workerBasic)));
      expect(normalized, containsAll([branchManager, projectManager]));
      expect(normalized.length, 2);
    });

    test('Worker -> Manager swaps worker-basic for branch-manager', () {
      final selected = [workerBasic];
      final normalized = RoleAssignmentPolicy.normalizeAfterTypeChange(
        WorkerType.manager,
        selected,
        catalog,
      );
      expect(normalized, [branchManager]);
    });

    test(
      'Manager -> Worker removes branch-manager and every custom role',
      () {
        final selected = [branchManager, projectManager, senior];
        final normalized = RoleAssignmentPolicy.normalizeAfterTypeChange(
          WorkerType.worker,
          selected,
          catalog,
        );
        expect(normalized, [workerBasic]);
      },
    );

    test('de-duplicates by id when the baseline is already selected', () {
      final selected = [branchManager, branchManager, projectManager];
      final normalized = RoleAssignmentPolicy.normalizeAfterTypeChange(
        WorkerType.manager,
        selected,
        catalog,
      );
      expect(normalized.length, 2);
      expect(normalized, containsAll([branchManager, projectManager]));
    });

    test('adds the baseline even when the prior selection was empty', () {
      final normalized = RoleAssignmentPolicy.normalizeAfterTypeChange(
        WorkerType.worker,
        const [],
        catalog,
      );
      expect(normalized, [workerBasic]);
    });
  });
}
