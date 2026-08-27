import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider_rbac/src/domain/entities/permission_entity.dart';
import 'package:provider_rbac/src/presentation/bloc/role_form/role_form_bloc.dart';
import 'package:provider_rbac/src/presentation/pages/role_form_page.dart';
import 'package:text_optimization/text_optimization.dart';

/// Widget-level coverage for [RoleFormPage]'s field validators
/// (`_validateName` / `_validateDescription`), which have no prior test
/// coverage — only the bloc's `canSubmit`/permission cross-field logic is
/// covered by `role_form_bloc_test.dart`. A [MockBloc] (bloc_test) stands
/// in for the real [RoleFormBloc] so no usecase/repository/DI wiring is
/// needed: `RoleFormPage` only ever reads bloc state and dispatches events,
/// both of which `MockBloc`/`whenListen` support directly.
class _MockRoleFormBloc extends MockBloc<RoleFormEvent, RoleFormState>
    implements RoleFormBloc {}

class _MockTextOptimizationRepository extends Mock
    implements TextOptimizationRepository {}

/// The description field's `AiEnhanceDescriptionField` resolves a
/// `TextOptimizationCubit` from `sl` (SAN-578) — never tapped here, but the
/// widget still needs one registered to build.
void _registerTextOptimizationCubit() {
  final repository = _MockTextOptimizationRepository();
  when(
    () => repository.optimize(any()),
  ).thenAnswer((_) => TaskEither.right(''));
  if (sl.isRegistered<TextOptimizationCubit>()) {
    sl.unregister<TextOptimizationCubit>();
  }
  sl.registerFactory<TextOptimizationCubit>(
    () => TextOptimizationCubit(OptimizeTextUseCase(repository)),
  );
}

const _perm1 = PermissionEntity(
  id: 'perm_1',
  action: 'branch:create',
  displayName: 'Create branch',
  resource: 'branch',
);

Future<void> _pump(
  WidgetTester tester,
  RoleFormBloc bloc, {
  required RoleFormState state,
}) async {
  whenListen(bloc, const Stream<RoleFormState>.empty(), initialState: state);

  // Since EasyLocalization isn't bootstrapped (see convention note above),
  // `.tr()` falls back to the raw key, e.g. 'common.enhance_with_ai' — far
  // longer than any real translation, which overflows
  // AppEnhanceWithAiButton's fixed-width (160px) pill. That's a byproduct
  // of the untranslated test key, not a real layout bug in the page under
  // test, so it's filtered out here. flutter_test reinstalls its own
  // FlutterError.onError at the start of every test body, so this must be
  // set from inside the test (here, not in setUp) to stick.
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.toString().contains('A RenderFlex overflowed')) return;
    originalOnError?.call(details);
  };
  addTearDown(() => FlutterError.onError = originalOnError);

  // The page's AppEnhanceWithAiButton overlay overflows the default (small)
  // test surface — use a realistic device-sized surface instead, matching
  // the convention in add_service_form_body_test.dart.
  await tester.binding.setSurfaceSize(const Size(1080, 2400));
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  // AppEnhanceWithAiButton runs a perpetual rainbow-border animation that
  // never settles on its own, which would hang `pumpAndSettle`; disabling
  // animations makes the widget stop its controller (it checks
  // `MediaQuery.disableAnimationsOf`).
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(
    tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
  );

  _registerTextOptimizationCubit();
  addTearDown(() {
    if (sl.isRegistered<TextOptimizationCubit>()) {
      sl.unregister<TextOptimizationCubit>();
    }
  });

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      builder: (_, _) => MaterialApp(
        theme: AppTheme.light(),
        home: BlocProvider<RoleFormBloc>.value(
          value: bloc,
          child: const RoleFormPage(),
        ),
      ),
    ),
  );
}

void main() {
  late _MockRoleFormBloc bloc;

  setUp(() {
    bloc = _MockRoleFormBloc();
  });

  // Permissions pre-selected so `canSubmit` is true and the submit button
  // is enabled — required to trigger `Form.validate()` via a tap, since
  // `_onSubmit` is only wired to `onPressed` when the bloc allows it.
  const submittableState = RoleFormState(
    catalogStatus: RequestStatus.success,
    permissions: [_perm1],
    selectedPermissionIds: {'perm_1'},
  );

  group('role name field', () {
    testWidgets('empty value shows the required error', (tester) async {
      await _pump(tester, bloc, state: submittableState);

      // Give the (now-required) description a valid value so only the name
      // field's own required error surfaces.
      await tester.enterText(find.byType(TextField).at(1), 'A description');
      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();

      expect(find.text('validation.required'), findsOneWidget);
    });

    testWidgets('101 characters shows the length error', (tester) async {
      await _pump(tester, bloc, state: submittableState);

      await tester.enterText(find.byType(TextField).first, 'a' * 101);
      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();

      expect(
        find.text('validation.length_range'),
        findsOneWidget,
      );
    });

    testWidgets('1-100 characters passes validation', (tester) async {
      await _pump(tester, bloc, state: submittableState);

      await tester.enterText(find.byType(TextField).first, 'a' * 100);
      // Description is required too; fill it so no unrelated required error
      // is picked up by the assertions below.
      await tester.enterText(find.byType(TextField).at(1), 'A description');
      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();

      expect(find.text('validation.required'), findsNothing);
      expect(
        find.text('validation.length_range'),
        findsNothing,
      );
    });
  });

  group('role description field (required, max 255)', () {
    testWidgets(
      'label is marked required, not optional (SAN-598)',
      (tester) async {
        await _pump(tester, bloc, state: submittableState);

        // No longer appends the "(optional)" suffix.
        expect(
          find.text('provider_rbac.description_label (common.optional)'),
          findsNothing,
        );
        final field = tester.widget<AiEnhanceDescriptionField>(
          find.byType(AiEnhanceDescriptionField),
        );
        expect(field.isRequired, isTrue);
      },
    );

    testWidgets('empty value shows the required error (SAN-598)', (
      tester,
    ) async {
      await _pump(tester, bloc, state: submittableState);

      // Name must be valid so only the description's own errors surface.
      await tester.enterText(find.byType(TextField).first, 'Valid name');
      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();

      // Two required errors would appear if the name were empty too; here
      // only the description contributes one.
      expect(find.text('validation.required'), findsOneWidget);
    });

    testWidgets('256 characters shows the max-length error', (tester) async {
      await _pump(tester, bloc, state: submittableState);

      await tester.enterText(find.byType(TextField).first, 'Valid name');
      await tester.enterText(
        find.byType(TextField).at(1),
        'a' * 256,
      );
      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();

      expect(
        find.text('validation.length_max'),
        findsOneWidget,
      );
    });

    testWidgets('255 characters (boundary) passes validation', (
      tester,
    ) async {
      await _pump(tester, bloc, state: submittableState);

      await tester.enterText(find.byType(TextField).first, 'Valid name');
      await tester.enterText(
        find.byType(TextField).at(1),
        'a' * 255,
      );
      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();

      expect(
        find.text('validation.length_max'),
        findsNothing,
      );
    });

    testWidgets('valid non-empty value passes validation', (tester) async {
      await _pump(tester, bloc, state: submittableState);

      await tester.enterText(find.byType(TextField).first, 'Valid name');
      await tester.enterText(
        find.byType(TextField).at(1),
        'A short description',
      );
      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();

      expect(
        find.text('validation.length_max'),
        findsNothing,
      );
    });
  });

  group('permissions section (SAN-590)', () {
    testWidgets('the section label is marked required', (tester) async {
      await _pump(tester, bloc, state: submittableState);

      final label = tester
          .widgetList<AppFieldLabel>(find.byType(AppFieldLabel))
          .firstWhere((w) => w.label == 'provider_rbac.permissions_label');
      expect(label.isRequired, isTrue);
    });
  });

  group('permission selection cross-field rule', () {
    testWidgets(
      'submit button is disabled when no permissions are selected '
      '(canSubmit rule owned by RoleFormBloc, see role_form_bloc_test.dart)',
      (tester) async {
        await _pump(
          tester,
          bloc,
          state: const RoleFormState(
            catalogStatus: RequestStatus.success,
            permissions: [_perm1],
          ),
        );

        final button = tester.widget<AppButton>(find.byType(AppButton));
        expect(button.onPressed, isNull);
      },
    );

    testWidgets('submit button is enabled once a permission is selected', (
      tester,
    ) async {
      await _pump(tester, bloc, state: submittableState);

      final button = tester.widget<AppButton>(find.byType(AppButton));
      expect(button.onPressed, isNotNull);
    });
  });
}
