import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_rbac/src/domain/entities/permission_entity.dart';
import 'package:provider_rbac/src/presentation/bloc/role_form/role_form_bloc.dart';
import 'package:provider_rbac/src/presentation/pages/role_form_page.dart';

/// Widget-level coverage for [RoleFormPage]'s field validators
/// (`_validateName` / `_validateDescription`), which have no prior test
/// coverage — only the bloc's `canSubmit`/permission cross-field logic is
/// covered by `role_form_bloc_test.dart`. A [MockBloc] (bloc_test) stands
/// in for the real [RoleFormBloc] so no usecase/repository/DI wiring is
/// needed: `RoleFormPage` only ever reads bloc state and dispatches events,
/// both of which `MockBloc`/`whenListen` support directly.
class _MockRoleFormBloc extends MockBloc<RoleFormEvent, RoleFormState>
    implements RoleFormBloc {}

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
  // `.tr()` falls back to the raw key, e.g. 'provider_rbac.enhance_with_ai'
  // — far longer than any real translation, which overflows
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

      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();

      expect(find.text('provider_rbac.validation_required'), findsOneWidget);
    });

    testWidgets('101 characters shows the length error', (tester) async {
      await _pump(tester, bloc, state: submittableState);

      await tester.enterText(find.byType(TextField).first, 'a' * 101);
      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();

      expect(
        find.text('provider_rbac.validation_length_error'),
        findsOneWidget,
      );
    });

    testWidgets('1-100 characters passes validation', (tester) async {
      await _pump(tester, bloc, state: submittableState);

      await tester.enterText(find.byType(TextField).first, 'a' * 100);
      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();

      expect(find.text('provider_rbac.validation_required'), findsNothing);
      expect(
        find.text('provider_rbac.validation_length_error'),
        findsNothing,
      );
    });
  });

  group('role description field (optional, max 255)', () {
    testWidgets('empty value shows no error (optional)', (tester) async {
      await _pump(tester, bloc, state: submittableState);

      // Name must be valid so only the description's own errors surface.
      await tester.enterText(find.byType(TextField).first, 'Valid name');
      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();

      expect(
        find.text('provider_rbac.validation_max_length_error'),
        findsNothing,
      );
      expect(find.text('provider_rbac.validation_required'), findsNothing);
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
        find.text('provider_rbac.validation_max_length_error'),
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
        find.text('provider_rbac.validation_max_length_error'),
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
        find.text('provider_rbac.validation_max_length_error'),
        findsNothing,
      );
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
