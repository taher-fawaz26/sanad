import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:branches/src/domain/entities/branch_time_slot_entity.dart';
import 'package:branches/src/domain/entities/branch_weekdays.dart';
import 'package:branches/src/presentation/widgets/branch_summary_view.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

// No EasyLocalization bootstrap — `.tr()` falls back to raw keys, which is
// fine: these tests assert which schedule rows appear (and that closed rows do
// NOT), not copy. "Closed" would resolve to the raw key
// `branches.details.closed`.

// Wide surface so the raw (long) i18n keys don't overflow the grouped rows.
const _surfaceSize = Size(2400, 1600);

// The SAN-780 real-device branch: CUSTOM schedule, all-caps day codes (as they
// exist after the data-source normalization boundary). Saturday has two slots.
const _customSchedule = [
  BranchAvailabilityEntity(
    day: BranchWeekdays.saturday,
    slots: [
      BranchTimeSlotEntity(from: '14:00', to: '18:00'),
      BranchTimeSlotEntity(from: '18:05', to: '21:00'),
    ],
  ),
  BranchAvailabilityEntity(
    day: BranchWeekdays.tuesday,
    slots: [BranchTimeSlotEntity(from: '10:00', to: '14:00')],
  ),
  BranchAvailabilityEntity(
    day: BranchWeekdays.friday,
    slots: [BranchTimeSlotEntity(from: '10:00', to: '14:00')],
  ),
];

BranchSummaryData _data(List<BranchAvailabilityEntity> schedule) =>
    BranchSummaryData(
      title: 'Al Dhaid',
      badgeLabel: 'active',
      badgeType: AppStatusBadgeType.success,
      branchTypeLabel: 'Main',
      phone: '+971501234567',
      schedule: schedule,
      isCustomSchedule: true,
      areaNames: const [],
      serviceNames: const [],
      workerInitials: const [],
    );

Future<void> _pump(WidgetTester tester, BranchSummaryData data) async {
  await tester.binding.setSurfaceSize(_surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      builder: (_, _) => MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(child: BranchSummaryView(data: data)),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets(
    'a CUSTOM schedule renders only the open days with their hours — no '
    '"Closed" rows for the four off days (SAN-780)',
    (tester) async {
      await _pump(tester, _data(_customSchedule));

      // The three configured days are present.
      expect(find.text('branches.add_branch.days.saturday'), findsOneWidget);
      expect(find.text('branches.add_branch.days.tuesday'), findsOneWidget);
      expect(find.text('branches.add_branch.days.friday'), findsOneWidget);

      // The four off days are omitted entirely — not rendered as "Closed".
      expect(find.text('branches.details.closed'), findsNothing);
      expect(find.text('branches.add_branch.days.sunday'), findsNothing);
      expect(find.text('branches.add_branch.days.monday'), findsNothing);
      expect(find.text('branches.add_branch.days.wednesday'), findsNothing);
      expect(find.text('branches.add_branch.days.thursday'), findsNothing);
    },
  );

  testWidgets('both slots of a multi-slot day are rendered (SAN-780)', (
    tester,
  ) async {
    await _pump(tester, _data(_customSchedule));

    // Saturday: 14:00–18:00 and 18:05–21:00 (12-hour, comma-joined).
    expect(find.textContaining('2:00 PM'), findsWidgets);
    expect(find.textContaining('6:05 PM'), findsOneWidget);
    expect(find.textContaining('9:00 PM'), findsOneWidget);
  });

  testWidgets(
    'a branch with no open days shows the empty state, not seven "Closed" rows',
    (tester) async {
      await _pump(tester, _data(const []));

      expect(find.text('branches.details.no_working_hours'), findsOneWidget);
      expect(find.text('branches.details.closed'), findsNothing);
    },
  );
}
