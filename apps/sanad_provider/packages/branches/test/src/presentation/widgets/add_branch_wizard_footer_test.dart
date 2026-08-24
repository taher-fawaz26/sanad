import 'package:branches/src/presentation/widgets/add_branch_wizard_footer.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

// No EasyLocalization bootstrap — `.tr()` falls back to the raw i18n key,
// matching add_branch_step_one_test.dart's convention. `AppTheme.light()`
// needs a `ScreenUtilInit` ancestor (responsive typography), same convention.
const _designSize = Size(400, 800);

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required bool coverageAccessDenied,
    required bool locationPermanentlyBlocked,
    VoidCallback? onOpenLocationSettings,
    VoidCallback? onRequestLocationAgain,
  }) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: _designSize,
        builder: (_, _) => MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: AddBranchWizardFooter(
              currentStep: 2,
              onNext: () {},
              onSubmit: () {},
              onAddCoverage: () {},
              onAddServices: () {},
              onAddWorkers: () {},
              coverageAccessDenied: coverageAccessDenied,
              locationPermanentlyBlocked: locationPermanentlyBlocked,
              onOpenLocationSettings: onOpenLocationSettings,
              onRequestLocationAgain: onRequestLocationAgain,
            ),
          ),
        ),
      ),
    );
  }

  group('AddBranchWizardFooter — Step 2 location gating (SAN-603)', () {
    testWidgets(
      'shows "Allow location access" (not Open Settings) when merely denied',
      (tester) async {
        var requested = false;
        await pump(
          tester,
          coverageAccessDenied: true,
          locationPermanentlyBlocked: false,
          onRequestLocationAgain: () => requested = true,
        );

        expect(
          find.text('branches.add_branch.location_allow_access'),
          findsOneWidget,
        );
        expect(find.text('common.open_settings'), findsNothing);

        await tester.tap(
          find.text('branches.add_branch.location_allow_access'),
        );
        expect(requested, isTrue);
      },
    );

    testWidgets(
      'shows "Open Settings" (not the retry button) when permanently '
      'blocked',
      (tester) async {
        var openedSettings = false;
        await pump(
          tester,
          coverageAccessDenied: true,
          locationPermanentlyBlocked: true,
          onOpenLocationSettings: () => openedSettings = true,
        );

        expect(find.text('common.open_settings'), findsOneWidget);
        expect(
          find.text('branches.add_branch.location_allow_access'),
          findsNothing,
        );

        await tester.tap(find.text('common.open_settings'));
        expect(openedSettings, isTrue);
      },
    );
  });
}
