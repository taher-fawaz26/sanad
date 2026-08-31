import 'package:branches/src/presentation/widgets/branch_summary_view.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

// No EasyLocalization bootstrap — `.tr()` falls back to raw keys, which is
// fine here: this test asserts the phone value's bidi wrapping, not copy.

// Wide surface so the raw (long) i18n keys don't overflow the grouped rows.
const _surfaceSize = Size(2400, 1600);

const _data = BranchSummaryData(
  title: 'Downtown',
  badgeLabel: 'active',
  badgeType: AppStatusBadgeType.success,
  branchTypeLabel: 'Main',
  phone: '+971585555255',
  schedule: [],
  areaNames: [],
  serviceNames: [],
  workerInitials: [],
);

Future<void> _pump(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(_surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      builder: (_, _) => MaterialApp(
        theme: AppTheme.light(),
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: SingleChildScrollView(
              child: BranchSummaryView(data: _data),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets(
    'the branch phone is rendered inside an LTR isolate so the `+` sits at '
    'the visual start under RTL (SAN-775)',
    (tester) async {
      await _pump(tester);

      // U+2066 LEFT-TO-RIGHT ISOLATE … U+2069 POP DIRECTIONAL ISOLATE.
      const isolated = '\u{2066}+971585555255\u{2069}';
      expect(find.text(isolated), findsOneWidget);
      expect(find.text('+971585555255'), findsNothing);
    },
  );
}
