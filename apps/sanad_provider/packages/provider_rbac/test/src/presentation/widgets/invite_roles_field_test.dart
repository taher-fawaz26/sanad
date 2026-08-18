// No EasyLocalization bootstrap (matches
// `manage_service_images_section_test.dart`) — `.tr()` calls fall back to
// the raw key.

import 'package:core/core.dart' hide Page;
import 'package:core/core.dart' as core show Page;
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider_rbac/src/domain/entities/role_entity.dart';
import 'package:provider_rbac/src/domain/entities/role_persona_type.dart';
import 'package:provider_rbac/src/domain/repositories/roles_repository.dart';
import 'package:provider_rbac/src/domain/usecases/get_roles_usecase.dart';
import 'package:provider_rbac/src/domain/usecases/roles_query.dart';
import 'package:provider_rbac/src/presentation/widgets/invite_roles_field.dart';
import 'package:workers/src/domain/entities/worker_type.dart';
import 'package:workers/src/presentation/services/worker_invite_roles_field.dart'
    show InviteRolesSelection;

class _MockRolesRepository extends Mock implements RolesRepository {}

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

final _workerBasic = _role(
  id: 'w1',
  name: 'worker-basic',
  isSystem: true,
  displayName: 'Worker',
);
final _branchManager = _role(
  id: 'm1',
  name: 'branch-manager',
  isSystem: true,
  displayName: 'Branch Manager',
);
final _projectManager = _role(
  id: 'c1',
  name: 'project-manager',
  isSystem: false,
  displayName: 'Project Manager',
);

Future<void> _pump(
  WidgetTester tester, {
  required WorkerType type,
  required ValueChanged<InviteRolesSelection> onChanged,
  required GetRolesUseCase getRolesUseCase,
  List<String> initialRoleIds = const [],
  Key? key,
}) async {
  await tester.binding.setSurfaceSize(const Size(1080, 2400));
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      builder: (_, _) => MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: InviteRolesField(
            key: key,
            type: type,
            onChanged: onChanged,
            getRolesUseCase: getRolesUseCase,
            initialRoleIds: initialRoleIds,
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(const RolesQuery());
  });

  late _MockRolesRepository repository;
  late GetRolesUseCase getRolesUseCase;
  late List<InviteRolesSelection> emitted;

  setUp(() {
    repository = _MockRolesRepository();
    getRolesUseCase = GetRolesUseCase(repository);
    emitted = [];
    when(() => repository.getRoles(any())).thenAnswer(
      (_) => TaskEither.of(
        core.Page(
          items: [_workerBasic, _branchManager, _projectManager],
          meta: const PageMeta(
            totalItems: 3,
            itemCount: 3,
            itemsPerPage: 100,
            totalPages: 1,
            currentPage: 1,
          ),
        ),
      ),
    );
  });

  testWidgets('resolves and locks the mandatory role once the catalog loads', (
    tester,
  ) async {
    await _pump(
      tester,
      type: WorkerType.worker,
      onChanged: emitted.add,
      getRolesUseCase: getRolesUseCase,
    );
    await tester.pumpAndSettle();

    expect(emitted.last.roleIds, [_workerBasic.id]);
    expect(emitted.last.isValid, isTrue);
    expect(find.text('Worker'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
  });

  testWidgets('adding an additional role via the sheet updates the selection', (
    tester,
  ) async {
    await _pump(
      tester,
      type: WorkerType.worker,
      onChanged: emitted.add,
      getRolesUseCase: getRolesUseCase,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(AppSelectField));
    await tester.pumpAndSettle();

    // Mandatory role row shows a lock badge, not a checkbox — it cannot be
    // toggled from the sheet. (The field behind the sheet also renders its
    // own lock badge on the mandatory chip, so at least one — not
    // necessarily exactly one — is expected here.)
    expect(find.byIcon(Icons.lock_outline), findsWidgets);

    final projectManagerCheckbox = find.descendant(
      of: find.ancestor(
        of: find.text('Project Manager'),
        matching: find.byType(AppTableRow),
      ),
      matching: find.byType(AppCheckbox),
    );
    await tester.tap(projectManagerCheckbox);
    await tester.pumpAndSettle();

    await tester.tap(find.text('common.confirm'));
    await tester.pumpAndSettle();

    expect(find.text('Project Manager'), findsOneWidget);
    expect(
      emitted.last.roleIds,
      containsAll([_workerBasic.id, _projectManager.id]),
    );
    expect(emitted.last.roleIds.length, 2);
  });

  testWidgets('searching the sheet filters the role list', (tester) async {
    await _pump(
      tester,
      type: WorkerType.worker,
      onChanged: emitted.add,
      getRolesUseCase: getRolesUseCase,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(AppSelectField));
    await tester.pumpAndSettle();

    expect(find.text('Project Manager'), findsOneWidget);
    // "Worker" appears twice: the sheet's own list row, plus the mandatory
    // chip on the field mounted underneath the sheet route.
    expect(find.text('Worker'), findsNWidgets(2));

    await tester.enterText(find.byType(TextField), 'project');
    await tester.pumpAndSettle();

    expect(find.text('Project Manager'), findsOneWidget);
    // Only the field's underlying chip remains — the sheet's "Worker" row
    // is filtered out by the search query.
    expect(find.text('Worker'), findsOneWidget);
  });

  testWidgets(
    'removing an additional role via its chip updates the selection',
    (tester) async {
      await _pump(
        tester,
        type: WorkerType.worker,
        onChanged: emitted.add,
        getRolesUseCase: getRolesUseCase,
        initialRoleIds: [_workerBasic.id, _projectManager.id],
      );
      await tester.pumpAndSettle();

      expect(find.text('Project Manager'), findsOneWidget);
      expect(emitted.last.roleIds, contains(_projectManager.id));

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Project Manager'), findsNothing);
      expect(emitted.last.roleIds, [_workerBasic.id]);
    },
  );

  testWidgets(
    'changing type from Worker to Manager swaps the baseline and keeps '
    'additional roles',
    (tester) async {
      final key = GlobalKey();
      await _pump(
        tester,
        key: key,
        type: WorkerType.worker,
        onChanged: emitted.add,
        getRolesUseCase: getRolesUseCase,
        initialRoleIds: [_projectManager.id],
      );
      await tester.pumpAndSettle();
      expect(emitted.last.roleIds, containsAll([_workerBasic.id, _projectManager.id]));

      await _pump(
        tester,
        key: key,
        type: WorkerType.manager,
        onChanged: emitted.add,
        getRolesUseCase: getRolesUseCase,
        initialRoleIds: [_projectManager.id],
      );
      await tester.pumpAndSettle();

      expect(emitted.last.roleIds, containsAll([_branchManager.id, _projectManager.id]));
      expect(emitted.last.roleIds, isNot(contains(_workerBasic.id)));
    },
  );
}
