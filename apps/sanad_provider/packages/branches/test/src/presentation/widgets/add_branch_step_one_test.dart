import 'package:branches/src/domain/entities/branch_manager_entity.dart';
import 'package:branches/src/domain/repositories/branch_repository.dart';
import 'package:branches/src/domain/usecases/create_branch_usecase.dart';
import 'package:branches/src/domain/usecases/get_company_schedule_usecase.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_bloc.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_draft_bloc.dart';
import 'package:branches/src/presentation/widgets/add_branch_step_one.dart';
import 'package:branches/src/presentation/widgets/branch_location_field.dart';
import 'package:branches/src/presentation/widgets/branch_manager_picker_field.dart';
import 'package:branches/src/presentation/widgets/branch_type_select_field.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maps/maps.dart';
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
  late AddBranchDraftBloc draftCubit;
  late AddBranchBloc addBranchBloc;
  late GlobalKey<FormState> formKey;

  setUp(() {
    repository = _MockBranchRepository();
    draftCubit = AddBranchDraftBloc();
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

  Future<void> pump(
    WidgetTester tester, {
    bool showValidationErrors = false,
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
              BlocProvider<AddBranchDraftBloc>.value(value: draftCubit),
              BlocProvider<AddBranchBloc>.value(value: addBranchBloc),
            ],
            child: Scaffold(
              body: AddBranchStepOne(
                formKey: formKey,
                onPickLocation: () {},
                currentStep: 1,
                totalSteps: 4,
                showValidationErrors: showValidationErrors,
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
      // The Form validates every field, not just name — phone must also be
      // valid for the whole form to pass (SAN-600 gating).
      await tester.enterText(phoneField(), '0501234567');
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
      await tester.enterText(phoneField(), '0501234567');
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
      await tester.enterText(phoneField(), '0501234567');
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

  group('branch name — free text, no character whitelist', () {
    for (final name in [
      'Dubai Marina Branch',
      'A1 @ Downtown - Main Office',
      '24/7 Home Services (Branch #2)',
      'فرع دبي الرئيسي',
      'مركز الخدمة #2',
      'فرع أبو ظبي / الرئيسي',
    ]) {
      testWidgets('"$name" is accepted', (tester) async {
        await pump(tester);

        await tester.enterText(nameField(), name);
        await tester.pump();
        await validate(tester);

        expect(find.text('validation.invalid_name'), findsNothing);
      });
    }

    for (final name in ['123456', '666666', '@@@@@@', '###---###', '......']) {
      testWidgets('"$name" (no letters) is rejected', (tester) async {
        await pump(tester);

        await tester.enterText(nameField(), name);
        await tester.pump();
        await validate(tester);

        expect(find.text('validation.invalid_name'), findsOneWidget);
      });
    }
  });

  group('branch phone validation — required, UAE mobile only', () {
    testWidgets('empty phone shows the required error', (tester) async {
      await pump(tester);

      await validate(tester);

      expect(find.text('validation.required'), findsOneWidget);
    });

    testWidgets('an invalid non-empty phone shows the UAE-phone error', (
      tester,
    ) async {
      await pump(tester);

      await tester.enterText(phoneField(), '123');
      await tester.pump();
      await validate(tester);

      expect(
        find.text('validation.form.uae_phone_invalid'),
        findsOneWidget,
      );
    });

    testWidgets('repeating-digit numbers are rejected (SAN-600)', (
      tester,
    ) async {
      for (final value in ['666666666', '66666666']) {
        await pump(tester);

        await tester.enterText(phoneField(), value);
        await tester.pump();
        await validate(tester);

        expect(
          find.text('validation.form.uae_phone_invalid'),
          findsOneWidget,
          reason: '$value must be rejected',
        );
      }
    });

    testWidgets('a landline number is rejected — mobile only', (
      tester,
    ) async {
      await pump(tester);

      // Valid UAE landline (04 Dubai prefix), invalid for a mobile-only field.
      await tester.enterText(phoneField(), '043334444');
      await tester.pump();
      await validate(tester);

      expect(
        find.text('validation.form.uae_phone_invalid'),
        findsOneWidget,
      );
    });

    testWidgets('a valid UAE mobile number passes with no error', (
      tester,
    ) async {
      await pump(tester);

      await tester.enterText(phoneField(), '0501234567');
      await tester.pump();
      await validate(tester);

      expect(
        find.text('validation.form.uae_phone_invalid'),
        findsNothing,
      );
      expect(find.text('validation.required'), findsNothing);
    });
  });

  group('required field indicators (SAN-599)', () {
    testWidgets(
      'name, type, city, location, phone, and manager are marked required',
      (tester) async {
        await pump(tester);

        expect(
          tester.widget<AppTextField>(find.byType(AppTextField)).isRequired,
          isTrue,
        );
        expect(
          tester
              .widget<BranchTypeSelectField>(
                find.byType(BranchTypeSelectField),
              )
              .isRequired,
          isTrue,
        );
        expect(
          tester
              .widget<BranchLocationField>(find.byType(BranchLocationField))
              .isRequired,
          isTrue,
        );
        expect(
          tester.widget<AppPhoneField>(find.byType(AppPhoneField)).isRequired,
          isTrue,
        );
        // Backend runtime contract requires branchManagerId despite Swagger
        // listing it as optional — see AddBranchDraft.isStepOneComplete.
        expect(
          tester
              .widget<BranchManagerPickerField>(
                find.byType(BranchManagerPickerField),
              )
              .isRequired,
          isTrue,
        );
      },
    );
  });

  group('branch manager — required (backend runtime contract)', () {
    testWidgets(
      'manager missing shows the inline required error once validation '
      'errors are surfaced (mirrors a failed Next attempt)',
      (tester) async {
        await pump(tester, showValidationErrors: true);

        expect(
          find.text('branches.add_branch.branch_manager_required'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'selecting a manager clears the inline required error',
      (tester) async {
        await pump(tester, showValidationErrors: true);
        expect(
          find.text('branches.add_branch.branch_manager_required'),
          findsOneWidget,
        );

        await tester.runAsync(() async {
          draftCubit.updateManager(
            const BranchManagerEntity(
              id: 'mgr-1',
              fullName: 'Test Manager',
              initials: 'TM',
            ),
          );
          await draftCubit.stream.firstWhere(
            (d) => d.selectedManager?.id == 'mgr-1',
          );
        });
        await tester.pump();
        await tester.pump();

        expect(
          find.text('branches.add_branch.branch_manager_required'),
          findsNothing,
        );
      },
    );
  });

  group('location — Place ID required (branch-create backend contract)', () {
    const address = 'Dubai Marina Mall, Marina Promenade';
    const position = LatLng(25.0772, 55.1401);

    testWidgets(
      'address set without a Place ID shows the select-from-search error '
      'even before a Next attempt (Next stays disabled, so the failed-Next '
      'reveal never fires)',
      (tester) async {
        await pump(tester);

        await tester.runAsync(() async {
          draftCubit.updateLocation(address: address, position: position);
          await draftCubit.stream.firstWhere(
            (d) => d.branchAddress == address,
          );
        });
        await tester.pump();
        await tester.pump();

        expect(
          find.text('branches.add_branch.location_select_from_search'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'address set with a Place ID shows no location error',
      (tester) async {
        await pump(tester);

        draftCubit.updateLocation(
          address: address,
          position: position,
          placeId: 'place-123',
        );
        await tester.pump();
        await tester.pump();

        expect(
          find.text('branches.add_branch.location_select_from_search'),
          findsNothing,
        );
        expect(
          find.text('branches.add_branch.location_required'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'empty address shows the required error only after validation errors '
      'are surfaced, not the select-from-search error',
      (tester) async {
        await pump(tester, showValidationErrors: true);

        expect(
          find.text('branches.add_branch.location_required'),
          findsOneWidget,
        );
        expect(
          find.text('branches.add_branch.location_select_from_search'),
          findsNothing,
        );
      },
    );
  });
}
