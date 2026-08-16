import 'package:branches/src/domain/entities/branch_availability_mode.dart';
import 'package:branches/src/domain/entities/branch_entity.dart';
import 'package:branches/src/domain/repositories/branch_repository.dart';
import 'package:branches/src/domain/usecases/delete_branch_usecase.dart';
import 'package:branches/src/domain/usecases/get_branches_usecase.dart';
import 'package:branches/src/domain/usecases/update_branch_status_usecase.dart';
import 'package:branches/src/presentation/bloc/branches/branches_bloc.dart';
import 'package:branches/src/presentation/pages/add_branch_page.dart';
import 'package:branches/src/presentation/widgets/branch_list_item.dart';
import 'package:branches/src/routes/branch_routes.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

// See service_list_item_test.dart for the root-cause note on why
// EasyLocalization isn't bootstrapped in this sandboxed test environment.

class _MockRepo extends Mock implements BranchRepository {}

const _branch = BranchEntity(
  id: 'b1',
  branchName: 'Downtown Branch',
  branchAddress: '123 Main St',
  city: 'Dubai',
  branchPhone: '+971500000000',
  isAvailable: true,
  availabilityMode: BranchAvailabilityMode.coreHours,
);

/// Placeholder standing in for the real `BranchDetailsPage` (which needs its
/// own BLoC/DI wiring) — only used to prove *which route* Edit navigates to.
class _FakeBranchDetailsPage extends StatelessWidget {
  const _FakeBranchDetailsPage();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Text('branch details placeholder'));
}

Future<void> _pumpRouter(WidgetTester tester, BranchesBloc bloc) async {
  const surfaceSize = Size(900, 1200);
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final router = GoRouter(
    initialLocation: BranchRoutes.list,
    routes: [
      GoRoute(
        path: BranchRoutes.list,
        builder: (context, state) => BlocProvider<BranchesBloc>.value(
          value: bloc,
          child: const Scaffold(body: BranchListItem(branch: _branch)),
        ),
      ),
      GoRoute(
        path: BranchRoutes.details,
        builder: (context, state) => const _FakeBranchDetailsPage(),
      ),
    ],
  );

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: surfaceSize,
      minTextAdapt: true,
      builder: (_, _) => MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late _MockRepo repo;
  late BranchesBloc bloc;
  late SemanticsHandle semanticsHandle;

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
    'swipe Edit navigates straight to Branch Details, not the Add Branch '
    'wizard, with no confirmation step',
    (tester) async {
      await _pumpRouter(tester, bloc);

      await tester.drag(
        find.text('Downtown Branch'),
        const Offset(-300, 0),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.bySemanticsLabel('branches.actions.action_edit'),
      );
      await tester.pumpAndSettle();

      // Direct navigation — no confirmation sheet appears in between.
      expect(find.byType(_FakeBranchDetailsPage), findsOneWidget);
      expect(find.byType(AddBranchPage), findsNothing);
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );
}
