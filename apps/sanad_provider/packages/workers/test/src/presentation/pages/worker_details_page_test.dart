import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workers/src/domain/entities/worker_entity.dart';
import 'package:workers/src/presentation/pages/worker_details_page.dart';
import 'package:workers/src/presentation/services/worker_role_assigner.dart';

// No EasyLocalization bootstrap (avoids a real SharedPreferences hang in this
// sandboxed test environment) — `.tr()` calls fall back to the raw key.

class _FakeWorkerRoleAssigner implements WorkerRoleAssigner {
  @override
  Widget buildRolesCard(String workerId) =>
      const Text('fake-assigned-roles-card');
}

const _worker = WorkerEntity(
  id: 'w-1',
  fullName: 'Sam Worker',
  role: 'worker',
  initials: 'SW',
);

void main() {
  setUp(() {
    sl.registerSingleton<WorkerRoleAssigner>(_FakeWorkerRoleAssigner());
  });

  tearDown(() {
    sl.unregister<WorkerRoleAssigner>();
  });

  Future<void> pump(WidgetTester tester, {required bool isOwner}) async {
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
          home: WorkerDetailsPage(
            workerId: _worker.id,
            initialWorker: _worker,
            isOwner: isOwner,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('isOwner: true', () {
    testWidgets('shows the assigned-roles card', (tester) async {
      await pump(tester, isOwner: true);

      expect(find.text('fake-assigned-roles-card'), findsOneWidget);
    });

    testWidgets('shows the Edit profile action', (tester) async {
      await pump(tester, isOwner: true);

      expect(find.text('workers.edit_profile'), findsOneWidget);
    });
  });

  group(
    'isOwner: false (RBAC Phase 7H — assigning roles and editing a worker '
    'are both owner-only)',
    () {
      testWidgets('hides the assigned-roles card', (tester) async {
        await pump(tester, isOwner: false);

        expect(find.text('fake-assigned-roles-card'), findsNothing);
      });

      testWidgets('hides the Edit profile action', (tester) async {
        await pump(tester, isOwner: false);

        expect(find.text('workers.edit_profile'), findsNothing);
      });

      testWidgets(
        'hides the Assigned Branches card (RBAC Phase 7M — assigning a '
        'worker to branches is `PATCH /workers/:id`, no update permission '
        'exists, finding G3)',
        (tester) async {
          await pump(tester, isOwner: false);

          expect(find.text('workers.assigned_branches_title'), findsNothing);
          expect(find.text('workers.no_assigned_branches'), findsNothing);
          expect(find.text('workers.assign_branch'), findsNothing);
        },
      );
    },
  );
}
