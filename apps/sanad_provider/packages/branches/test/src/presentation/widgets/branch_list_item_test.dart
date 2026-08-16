import 'package:branches/src/domain/entities/branch_availability_mode.dart';
import 'package:branches/src/domain/entities/branch_entity.dart';
import 'package:branches/src/domain/repositories/branch_repository.dart';
import 'package:branches/src/domain/usecases/branch_usecase_params.dart';
import 'package:branches/src/domain/usecases/delete_branch_usecase.dart';
import 'package:branches/src/domain/usecases/get_branches_usecase.dart';
import 'package:branches/src/domain/usecases/update_branch_status_usecase.dart';
import 'package:branches/src/presentation/bloc/branches/branches_bloc.dart';
import 'package:branches/src/presentation/widgets/branch_list_item.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

// See services/test/.../service_list_item_test.dart for the full root-cause
// note: no EasyLocalization bootstrap (avoids a real SharedPreferences hang
// in this sandboxed test environment), and a matched design/surface size
// (avoids status-badge/text overflowing on the raw `.tr()` fallback key).

class _MockRepo extends Mock implements BranchRepository {}

const _activeBranch = BranchEntity(
  id: 'b1',
  branchName: 'Downtown Branch',
  branchAddress: '123 Main St',
  city: 'Dubai',
  branchPhone: '+971500000000',
  isAvailable: true,
  availabilityMode: BranchAvailabilityMode.coreHours,
);

const _maintenanceBranch = BranchEntity(
  id: 'b2',
  branchName: 'Marina Branch',
  branchAddress: '456 Marina Rd',
  city: 'Dubai',
  branchPhone: '+971500000001',
  isAvailable: false,
  availabilityMode: BranchAvailabilityMode.coreHours,
);

const _surfaceSize = Size(900, 1200);

Future<void> _pump(
  WidgetTester tester, {
  required BranchesBloc bloc,
  BranchEntity? branch,
  VoidCallback? onTap,
}) async {
  await tester.binding.setSurfaceSize(_surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: _surfaceSize,
      minTextAdapt: true,
      builder: (_, _) => MaterialApp(
        theme: AppTheme.light(),
        home: BlocProvider<BranchesBloc>.value(
          value: bloc,
          child: Scaffold(
            body: BranchListItem(
              branch: branch ?? _activeBranch,
              onTap: onTap,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openSwipePane(
  WidgetTester tester, {
  String title = 'Downtown Branch',
}) async {
  await tester.drag(find.text(title), const Offset(-300, 0));
  await tester.pumpAndSettle();
}

Future<void> _confirm(WidgetTester tester, String actionLabelKey) async {
  await tester.pumpAndSettle();
  await tester.tap(find.text(actionLabelKey));
  await tester.pumpAndSettle();
}

void main() {
  group('BranchListItem swipe actions', () {
    late _MockRepo repo;
    late BranchesBloc bloc;
    late SemanticsHandle semanticsHandle;

    setUpAll(() {
      registerFallbackValue(const DeleteBranchParams(id: 'fallback'));
    });

    setUp(() {
      repo = _MockRepo();
      bloc = BranchesBloc(
        getBranchesUseCase: GetBranchesUseCase(repo),
        deleteBranchUseCase: DeleteBranchUseCase(repo),
        updateBranchStatusUseCase: UpdateBranchStatusUseCase(repo),
      );
      semanticsHandle = WidgetsBinding.instance.ensureSemantics();
    });

    tearDown(() {
      semanticsHandle.dispose();
      bloc.close();
    });

    testWidgets(
      'renders branch name and status badge',
      (tester) async {
        await _pump(tester, bloc: bloc);

        expect(find.text('Downtown Branch'), findsOneWidget);
        expect(find.text('branches.status_active'), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'exposes no More button / more_vert entry point',
      (tester) async {
        await _pump(tester, bloc: bloc);

        expect(find.byIcon(Icons.more_vert), findsNothing);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'row tap invokes onTap',
      (tester) async {
        var tapped = false;
        await _pump(tester, bloc: bloc, onTap: () => tapped = true);

        await tester.tap(find.text('Downtown Branch'));
        await tester.pumpAndSettle();

        expect(tapped, isTrue);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'swipe reveals Edit / Set-to-maintenance / Delete for an active branch',
      (tester) async {
        await _pump(tester, bloc: bloc);

        await _openSwipePane(tester);

        expect(
          find.bySemanticsLabel('branches.actions.action_edit'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('branches.actions.action_set_maintenance'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('branches.actions.action_set_active'),
          findsNothing,
        );
        expect(
          find.bySemanticsLabel('branches.actions.action_delete'),
          findsOneWidget,
        );
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'swipe reveals Set-to-active for a branch under maintenance',
      (tester) async {
        await _pump(tester, bloc: bloc, branch: _maintenanceBranch);

        await _openSwipePane(tester, title: 'Marina Branch');

        expect(
          find.bySemanticsLabel('branches.actions.action_set_active'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('branches.actions.action_set_maintenance'),
          findsNothing,
        );
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'Maintenance swipe action confirms then toggles status via the bloc',
      (tester) async {
        when(
          () => repo.updateBranchStatus(
            const UpdateBranchStatusParams(id: 'b1', isAvailable: false),
          ),
        ).thenAnswer(
          (_) => TaskEither.of(_activeBranch.copyWith(isAvailable: false)),
        );

        await _pump(tester, bloc: bloc);
        await _openSwipePane(tester);

        await tester.tap(
          find.bySemanticsLabel('branches.actions.action_set_maintenance'),
        );
        await _confirm(tester, 'common.confirm');

        verify(
          () => repo.updateBranchStatus(
            const UpdateBranchStatusParams(id: 'b1', isAvailable: false),
          ),
        ).called(1);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'Delete swipe action confirms then calls delete via the bloc',
      (tester) async {
        when(
          () => repo.deleteBranch(const DeleteBranchParams(id: 'b1')),
        ).thenAnswer((_) => TaskEither<Failure, void>.of(null));

        await _pump(tester, bloc: bloc);
        await _openSwipePane(tester);

        await tester.tap(
          find.bySemanticsLabel('branches.actions.action_delete'),
        );
        await _confirm(tester, 'common.delete');

        verify(
          () => repo.deleteBranch(const DeleteBranchParams(id: 'b1')),
        ).called(1);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'cancelling the confirmation sheet does not call delete',
      (tester) async {
        await _pump(tester, bloc: bloc);
        await _openSwipePane(tester);

        await tester.tap(
          find.bySemanticsLabel('branches.actions.action_delete'),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('common.cancel'));
        await tester.pumpAndSettle();

        verifyNever(() => repo.deleteBranch(any()));
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );
  });
}
