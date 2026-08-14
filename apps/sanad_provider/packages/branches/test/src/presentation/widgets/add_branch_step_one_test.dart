import 'package:branches/src/domain/repositories/branch_repository.dart';
import 'package:branches/src/domain/usecases/create_branch_usecase.dart';
import 'package:branches/src/domain/usecases/get_company_schedule_usecase.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_bloc.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_draft_cubit.dart';
import 'package:branches/src/presentation/widgets/add_branch_step_one.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// No EasyLocalization bootstrap (matches branch_review_body_test.dart's
// convention) — `.tr()` falls back to the raw i18n key, so assertions target
// those raw keys directly.

class _MockBranchRepository extends Mock implements BranchRepository {}

// Wide surface: AddBranchStepOne renders the full step-1 form (name, type,
// city, location, phone, manager, working hours). With no EasyLocalization
// bootstrap, `.tr()` falls back to raw (long) i18n keys, which overflow the
// location field's action-button row at normal phone widths — widen the
// surface instead of bootstrapping real translations (matches
// branch_review_body_test.dart's approach).
const _surfaceSize = Size(4000, 3600);

void main() {
  late _MockBranchRepository repository;
  late AddBranchDraftCubit draftCubit;
  late AddBranchBloc addBranchBloc;
  late GlobalKey<FormState> formKey;

  setUp(() {
    repository = _MockBranchRepository();
    draftCubit = AddBranchDraftCubit();
    addBranchBloc = AddBranchBloc(
      createBranchUseCase: CreateBranchUseCase(repository),
      getCompanyScheduleUseCase: GetCompanyScheduleUseCase(repository),
    );
    formKey = GlobalKey<FormState>();
  });

  tearDown(() async {
    await draftCubit.close();
    await addBranchBloc.close();
  });

  Future<void> pump(WidgetTester tester) async {
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
              body: AddBranchStepOne(
                formKey: formKey,
                onPickLocation: () {},
                currentStep: 1,
                totalSteps: 4,
              ),
            ),
          ),
        ),
      ),
    );
    // Not pumpAndSettle: some child fields (e.g. loading/skeleton affordances
    // inside the picker fields) run continuous animations that never settle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  Finder nameField() => find.descendant(
    of: find.byType(AppTextField),
    matching: find.byType(TextField),
  );

  Finder phoneField() => find.descendant(
    of: find.byType(AppPhoneField),
    matching: find.byType(TextField),
  );

  Future<bool> validate(WidgetTester tester) async {
    final isValid = formKey.currentState!.validate();
    await tester.pump();
    return isValid;
  }

  group('branch name validation', () {
    testWidgets('empty name shows the required error', (tester) async {
      await pump(tester);

      final isValid = await validate(tester);

      expect(isValid, isFalse);
      expect(
        find.text('branches.add_branch.branch_name_required'),
        findsOneWidget,
      );
    });

    testWidgets(
      '256 characters shows the max-length error (no minimum enforced)',
      (tester) async {
        await pump(tester);

        await tester.enterText(nameField(), 'a' * 256);
        await tester.pump();
        final isValid = await validate(tester);

        expect(isValid, isFalse);
        expect(
          find.text('branches.add_branch.branch_name_max_length_error'),
          findsOneWidget,
        );
      },
    );

    testWidgets('exactly 255 characters passes', (tester) async {
      await pump(tester);

      await tester.enterText(nameField(), 'a' * 255);
      await tester.pump();
      final isValid = await validate(tester);

      expect(isValid, isTrue);
      expect(
        find.text('branches.add_branch.branch_name_required'),
        findsNothing,
      );
      expect(
        find.text('branches.add_branch.branch_name_max_length_error'),
        findsNothing,
      );
    });

    testWidgets('a short (2-char) name is valid — no invented minimum', (
      tester,
    ) async {
      await pump(tester);

      await tester.enterText(nameField(), 'AB');
      await tester.pump();
      final isValid = await validate(tester);

      expect(isValid, isTrue);
      expect(
        find.text('branches.add_branch.branch_name_required'),
        findsNothing,
      );
      expect(
        find.text('branches.add_branch.branch_name_max_length_error'),
        findsNothing,
      );
    });

    testWidgets('a valid mid-length name passes with no error', (
      tester,
    ) async {
      await pump(tester);

      await tester.enterText(nameField(), 'Downtown Branch');
      await tester.pump();
      final isValid = await validate(tester);

      expect(isValid, isTrue);
      expect(
        find.text('branches.add_branch.branch_name_required'),
        findsNothing,
      );
      expect(
        find.text('branches.add_branch.branch_name_max_length_error'),
        findsNothing,
      );
    });
  });

  group('branch phone validation — optional field', () {
    testWidgets('empty phone shows no error (phone is optional)', (
      tester,
    ) async {
      await pump(tester);

      // Only the name is required for the form to reject; the phone leg of
      // `validate()` must not add its own error when left blank.
      await validate(tester);

      expect(find.text('branches.add_branch.invalid_phone'), findsNothing);
    });

    testWidgets('an invalid non-empty phone shows a format error', (
      tester,
    ) async {
      await pump(tester);

      await tester.enterText(phoneField(), '123');
      await tester.pump();
      await validate(tester);

      expect(find.text('branches.add_branch.invalid_phone'), findsOneWidget);
    });

    testWidgets('a valid UAE mobile number passes with no error', (
      tester,
    ) async {
      await pump(tester);

      await tester.enterText(phoneField(), '0501234567');
      await tester.pump();
      await validate(tester);

      expect(find.text('branches.add_branch.invalid_phone'), findsNothing);
    });
  });
}
