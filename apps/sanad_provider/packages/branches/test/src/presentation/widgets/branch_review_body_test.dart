import 'package:branches/src/domain/entities/branch_type.dart';
import 'package:branches/src/domain/repositories/branch_repository.dart';
import 'package:branches/src/domain/usecases/branch_usecase_params.dart';
import 'package:branches/src/domain/usecases/create_branch_usecase.dart';
import 'package:branches/src/domain/usecases/get_company_schedule_usecase.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_bloc.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_draft_cubit.dart';
import 'package:branches/src/presentation/widgets/branch_review_body.dart';
import 'package:branches/src/presentation/widgets/branch_summary_view.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

// No EasyLocalization bootstrap (avoids a real SharedPreferences hang in this
// sandboxed test environment) — `.tr()` calls fall back to the raw key, which
// is fine since these tests assert wiring/structure, not localized text.

class _MockBranchRepository extends Mock implements BranchRepository {}

// Wide surface: with no EasyLocalization bootstrap, `.tr()` falls back to
// raw (long) i18n keys, which overflow AppGroupedKeyValueList rows at normal
// phone widths. Widening the surface avoids that render error without
// bootstrapping real translations (see note above).
const _surfaceSize = Size(2400, 1600);

const _validParams = CreateBranchParams(
  branchName: 'x',
  branchType: BranchType.mainBranch,
  branchAddress: 'x',
  locationPlaceId: 'ChIJvRmU9K1DXz4RYKyuhY6v0wM',
  branchPhone: 'x',
  branchManagerId: 'x',
  lat: 0,
  lng: 0,
  radiusKm: 1,
  workerIds: [],
);

void main() {
  late _MockBranchRepository repository;
  late AddBranchDraftCubit draftCubit;
  late AddBranchBloc addBranchBloc;

  setUpAll(() {
    registerFallbackValue(_validParams);
    registerFallbackValue(
      const UpdateBranchParams(
        id: 'x',
        branchName: 'x',
        branchAddress: 'x',
        branchPhone: 'x',
      ),
    );
  });

  /// Drives the real bloc to a submit failure the same way a real backend
  /// validation error would — through `AddBranchSubmitEvent`, not by
  /// reaching into the bloc's protected `emit`. Uses `runAsync` because the
  /// mocked use case's `Future` resolves outside the widget-test fake clock;
  /// plain `pump()`/`pumpAndSettle()` calls don't reliably flush it.
  Future<void> failSubmit(WidgetTester tester, Failure failure) async {
    when(
      () => repository.createBranch(any()),
    ).thenAnswer((_) => TaskEither.left(failure));
    await tester.runAsync(() async {
      addBranchBloc.add(const AddBranchSubmitEvent(params: _validParams));
      await addBranchBloc.stream.firstWhere(
        (s) => s.status == RequestStatus.failure,
      );
    });
    await tester.pumpAndSettle();
  }

  setUp(() {
    repository = _MockBranchRepository();
    draftCubit = AddBranchDraftCubit();
    addBranchBloc = AddBranchBloc(
      createBranchUseCase: CreateBranchUseCase(repository),
      getCompanyScheduleUseCase: GetCompanyScheduleUseCase(repository),
    );
  });

  tearDown(() async {
    await draftCubit.close();
    await addBranchBloc.close();
  });

  Future<void> pump(
    WidgetTester tester, {
    VoidCallback? onEditCoverage,
    VoidCallback? onEditServices,
    VoidCallback? onEditTeam,
  }) async {
    await tester.binding.setSurfaceSize(_surfaceSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: _surfaceSize,
        minTextAdapt: true,
        builder: (_, _) => MaterialApp(
          theme: AppTheme.light(),
          home: MultiBlocProvider(
            providers: [
              BlocProvider<AddBranchDraftCubit>.value(value: draftCubit),
              BlocProvider<AddBranchBloc>.value(value: addBranchBloc),
            ],
            child: Scaffold(
              body: BranchReviewBody(
                onEditCoverage: onEditCoverage ?? () {},
                onEditServices: onEditServices ?? () {},
                onEditTeam: onEditTeam ?? () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  BranchSummaryView summaryView(WidgetTester tester) =>
      tester.widget<BranchSummaryView>(find.byType(BranchSummaryView));

  group('BranchReviewBody', () {
    testWidgets('renders every section with an edit affordance wired', (
      tester,
    ) async {
      await pump(tester);

      final view = summaryView(tester);
      expect(view.onEditBranchInfo, isNotNull);
      expect(view.onEditContact, isNotNull);
      expect(view.onEditWorkingHours, isNotNull);
      expect(view.onEditCoverage, isNotNull);
      expect(view.onEditServices, isNotNull);
      expect(view.onEditTeam, isNotNull);
    });

    testWidgets(
      'coverage/services/team pencils invoke the wizard-provided handlers '
      '(reused, not duplicated)',
      (tester) async {
        var coverageTapped = 0;
        var servicesTapped = 0;
        var teamTapped = 0;

        await pump(
          tester,
          onEditCoverage: () => coverageTapped++,
          onEditServices: () => servicesTapped++,
          onEditTeam: () => teamTapped++,
        );

        summaryView(tester).onEditCoverage!();
        summaryView(tester).onEditServices!();
        summaryView(tester).onEditTeam!();

        expect(coverageTapped, 1);
        expect(servicesTapped, 1);
        expect(teamTapped, 1);
      },
    );

    testWidgets(
      'editing a section updates the single draft and the review rebuilds '
      'from it — no network call occurs',
      (tester) async {
        await pump(tester);

        draftCubit.updateBasicInfo(branchName: 'Downtown Branch');
        await tester.pumpAndSettle();

        expect(summaryView(tester).data.branchTypeLabel, isNotEmpty);
        expect(draftCubit.state.branchName, 'Downtown Branch');
        verifyNever(() => repository.createBranch(any()));
        verifyNever(() => repository.updateBranch(any()));
      },
    );

    testWidgets(
      "card title is the branch's own name (the draft), never a "
      'hardcoded/localized company name — mirrors BranchDetailsPage',
      (tester) async {
        draftCubit.updateBasicInfo(branchName: 'Downtown Branch');
        await pump(tester);

        expect(summaryView(tester).data.title, 'Downtown Branch');
        expect(find.text('Ghabbour Service Centre'), findsNothing);
        expect(find.text('branches.company_name'), findsNothing);
      },
    );

    testWidgets(
      'card title tracks the branch name as the user edits Step 1',
      (tester) async {
        draftCubit.updateBasicInfo(branchName: 'First Name');
        await pump(tester);
        expect(summaryView(tester).data.title, 'First Name');

        draftCubit.updateBasicInfo(branchName: 'Renamed Branch');
        await tester.pumpAndSettle();

        expect(summaryView(tester).data.title, 'Renamed Branch');
      },
    );

    testWidgets(
      'a backend validation failure mentioning "availability" highlights '
      'the Working Hours section without touching the draft',
      (tester) async {
        await pump(tester);
        draftCubit.updateBasicInfo(branchName: 'Keep Me');

        await failSubmit(
          tester,
          const ValidationFailure(
            message: 'availability must contain at least 1 elements',
            messages: ['availability must contain at least 1 elements'],
          ),
        );

        expect(
          summaryView(tester).highlightedSection,
          BranchSummarySection.workingHours,
        );
        // The draft (the user's in-progress data) must survive the failure.
        expect(draftCubit.state.branchName, 'Keep Me');
      },
    );

    testWidgets(
      'a failure matched to Team can be fixed by editing Team without '
      'restarting the wizard, and the highlight clears on edit',
      (tester) async {
        var teamTapped = 0;
        await pump(tester, onEditTeam: () => teamTapped++);

        await failSubmit(
          tester,
          const ValidationFailure(
            message: 'workers must contain at least 1 elements',
            messages: ['workers must contain at least 1 elements'],
          ),
        );
        expect(
          summaryView(tester).highlightedSection,
          BranchSummarySection.team,
        );

        summaryView(tester).onEditTeam!();
        await tester.pumpAndSettle();

        expect(teamTapped, 1);
        expect(summaryView(tester).highlightedSection, isNull);
      },
    );

    testWidgets(
      'a failure with no keyword match highlights nothing (no invented '
      'section targeting)',
      (tester) async {
        await pump(tester);

        await failSubmit(
          tester,
          const ServerFailure(message: 'Something went wrong'),
        );

        expect(summaryView(tester).highlightedSection, isNull);
      },
    );
  });
}
