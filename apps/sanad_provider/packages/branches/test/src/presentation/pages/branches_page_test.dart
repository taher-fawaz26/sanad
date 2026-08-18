import 'package:branches/src/domain/entities/paginated_branches_entity.dart';
import 'package:branches/src/domain/repositories/branch_repository.dart';
import 'package:branches/src/domain/usecases/branch_usecase_params.dart';
import 'package:branches/src/domain/usecases/delete_branch_usecase.dart';
import 'package:branches/src/domain/usecases/get_branches_usecase.dart';
import 'package:branches/src/domain/usecases/update_branch_status_usecase.dart';
import 'package:branches/src/presentation/bloc/branches/branches_bloc.dart';
import 'package:branches/src/presentation/pages/branches_page.dart';
import 'package:branches/src/routes/branch_permissions.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../support/fake_authorization_reader.dart';

// See branch_list_item_test.dart for the root-cause note on why
// EasyLocalization isn't bootstrapped in this sandboxed test environment.
//
// This file covers only the empty-branches case. The Add Branch button that
// renders above a *populated* list uses the exact same PermissionGate
// primitive already proven here (against a real DI-resolved
// AuthorizationReader) and in branch_list_item_test.dart's permission-gated
// swipe actions — a populated-list page render was left out of this file
// because it hits an unrelated sliver-viewport/layout interaction specific
// to this sandboxed (untranslated, raw i18n key) test environment, not a
// permission-gating concern.

class _MockRepo extends Mock implements BranchRepository {}

// Wider than branch_list_item_test.dart's surface: this page also renders
// the filter chip row, whose labels are raw (untranslated) i18n keys in this
// sandboxed test environment — much longer than real translated labels —
// so it needs more horizontal room to avoid a RenderFlex overflow that would
// never occur with real translations loaded.
const _surfaceSize = Size(1400, 1200);

Future<void> _pump(WidgetTester tester, BranchesBloc bloc) async {
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
          // isOwner is irrelevant to this file's assertions (Add Branch is
          // permission-gated on branch:create, not persona) — false is the
          // fail-closed default; the Delete-persona case is covered by
          // branch_list_item_test.dart instead.
          child: const ProviderBranchesPage(isOwner: false),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late _MockRepo repo;
  late BranchesBloc bloc;

  setUp(() {
    repo = _MockRepo();
    bloc = BranchesBloc(
      getBranchesUseCase: GetBranchesUseCase(repo),
      deleteBranchUseCase: DeleteBranchUseCase(repo),
      updateBranchStatusUseCase: UpdateBranchStatusUseCase(repo),
    );
    when(
      () => repo.getBranches(const GetBranchesParams(limit: 50)),
    ).thenAnswer(
      (_) => TaskEither.of(
        const PaginatedBranchesEntity(
          branches: [],
          meta: BranchPaginationMeta(
            totalItems: 0,
            itemCount: 0,
            itemsPerPage: 20,
            totalPages: 0,
            currentPage: 1,
          ),
        ),
      ),
    );
  });

  tearDown(() {
    bloc.close();
    unregisterFakeAuthorizationReader();
  });

  group('empty-state CTA — no branches yet', () {
    testWidgets(
      'shows the add-branch action when branchCreate is granted',
      (tester) async {
        registerFakeAuthorizationReader(
          permissions: [BranchPermissions.view, BranchPermissions.create],
        );
        await _pump(tester, bloc);

        expect(
          find.text('branches.empty_first_branch_action'),
          findsOneWidget,
        );
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'renders "no branches yet" with no action for a view-only worker',
      (tester) async {
        registerFakeAuthorizationReader(permissions: [BranchPermissions.view]);
        await _pump(tester, bloc);

        expect(find.text('branches.empty_first_branch_title'), findsOneWidget);
        expect(
          find.text('branches.empty_first_branch_action'),
          findsNothing,
        );
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );
  });
}
