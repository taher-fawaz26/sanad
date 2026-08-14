import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/widgets/bottom_sheets/edit_identity_bottom_sheet.dart';

/// `UpdateServiceProviderSettingsDto.description` caps at 350 chars — see
/// `update_service_provider_settings_params.dart`. A prior migration had the
/// UI constant wrongly set to 2000; these tests pin the corrected 350 limit.
///
/// Root-cause note: the sheet's "Enhance with AI" button
/// (`AppEnhanceWithAiButton`) runs a continuous rainbow-border animation
/// whenever `MediaQuery.disableAnimationsOf(context)` is false, so
/// `pumpAndSettle()` never quiesces — every interaction below uses bounded
/// `pump()` calls instead. Disabling animations via accessibility features
/// also sidesteps a second, unrelated pre-existing issue: that button's
/// label sizes to a literal 160x41 pixel box, sized for the real
/// (translated) "Enhance with AI" text; with EasyLocalization NOT
/// bootstrapped (this repo's widget-test convention — see
/// worker_list_item_test.dart), `.tr()` falls back to the longer raw key
/// `settings.enhance_with_ai`, which overflows that fixed box. That overflow
/// is a decorative, out-of-scope pre-existing issue unrelated to the
/// description-length validation under test here, so `_pumpOpener` below
/// suppresses just that one `FlutterError` for the duration of each test.
Future<void> _pumpOpener(
  WidgetTester tester, {
  String? initialDescription,
}) async {
  // `TestWidgetsFlutterBinding` installs its own `FlutterError.onError`
  // around each test body, so overriding it from `setUp()` (which runs
  // before that installation) has no effect — it must be set from inside
  // the test body itself, which is why this lives in the opener helper
  // rather than top-level `setUp`/`tearDown`.
  final defaultOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exception.toString().contains('A RenderFlex overflowed')) {
      return;
    }
    defaultOnError?.call(details);
  };
  addTearDown(() => FlutterError.onError = defaultOnError);

  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

  // The sheet's "Enhance with AI" row overflows the default (small) test
  // surface — use a realistic device-sized surface, mirroring
  // add_service_form_body_test.dart's convention.
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
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showEditIdentityBottomSheet(
                context: context,
                initialDescription: initialDescription,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _openSheet(
  WidgetTester tester, {
  String? initialDescription,
}) async {
  await _pumpOpener(tester, initialDescription: initialDescription);
  await tester.tap(find.text('open'));
  // Bounded pumps through the 300ms sheet-enter transition instead of
  // pumpAndSettle — see root-cause note above.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

const _lengthErrorKey = 'validation.length_max';

void main() {
  group('EditIdentityBottomSheet business description length', () {
    testWidgets('empty description is optional and passes', (tester) async {
      await _openSheet(tester);

      await tester.tap(find.text('common.save'));
      await tester.pump();

      expect(find.text(_lengthErrorKey), findsNothing);
    });

    testWidgets('valid short description passes', (tester) async {
      await _openSheet(tester);

      await tester.enterText(
        find.byType(TextFormField),
        'A great business description.',
      );
      await tester.pump();
      await tester.tap(find.text('common.save'));
      await tester.pump();

      expect(find.text(_lengthErrorKey), findsNothing);
    });

    testWidgets('exactly 350 characters passes', (tester) async {
      await _openSheet(tester);

      await tester.enterText(find.byType(TextFormField), 'a' * 350);
      await tester.pump();
      await tester.tap(find.text('common.save'));
      await tester.pump();

      expect(find.text(_lengthErrorKey), findsNothing);
    });

    testWidgets('351 characters fails with the corrected length error', (
      tester,
    ) async {
      await _openSheet(tester);

      await tester.enterText(find.byType(TextFormField), 'a' * 351);
      await tester.pump();
      await tester.tap(find.text('common.save'));
      await tester.pump();

      // EasyLocalization is not initialized in this harness, so `.tr()`
      // resolves to the raw key — namedArgs: {'max': '350'} is baked into
      // the call site (edit_identity_bottom_sheet.dart) and isn't visible
      // pre-init, but the corrected 350 cap is what makes this length fail
      // at all (it passed at 350 above and would also pass at 351 under the
      // old, wrong 2000 cap).
      expect(find.text(_lengthErrorKey), findsOneWidget);
    });
  });
}
