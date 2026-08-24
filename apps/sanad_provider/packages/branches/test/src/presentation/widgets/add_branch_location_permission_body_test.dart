import 'package:branches/src/presentation/widgets/add_branch_location_permission_body.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maps/maps.dart';

// No EasyLocalization bootstrap — `.tr()` falls back to the raw i18n key,
// matching add_branch_step_one_test.dart's convention. `AppTheme.light()`
// needs a `ScreenUtilInit` ancestor (responsive typography), same convention.
const _designSize = Size(400, 800);

void main() {
  Future<void> pump(
    WidgetTester tester,
    LocationPermissionStatus status,
  ) => tester.pumpWidget(
    ScreenUtilInit(
      designSize: _designSize,
      builder: (_, _) => MaterialApp(
        theme: AppTheme.light(),
        home: AddBranchLocationPermissionBody(status: status),
      ),
    ),
  );

  group('AddBranchLocationPermissionBody', () {
    testWidgets('denied shows the in-app rationale copy', (tester) async {
      await pump(tester, LocationPermissionStatus.denied);

      expect(
        find.text('branches.add_branch.location_permission_title'),
        findsOneWidget,
      );
    });

    testWidgets('permanentlyDenied shows the settings copy', (tester) async {
      await pump(tester, LocationPermissionStatus.permanentlyDenied);

      expect(
        find.text('branches.add_branch.location_access_title'),
        findsOneWidget,
      );
    });

    testWidgets('serviceDisabled shows the service-disabled copy', (
      tester,
    ) async {
      await pump(tester, LocationPermissionStatus.serviceDisabled);

      expect(
        find.text('branches.add_branch.location_service_disabled_title'),
        findsOneWidget,
      );
    });
  });
}
