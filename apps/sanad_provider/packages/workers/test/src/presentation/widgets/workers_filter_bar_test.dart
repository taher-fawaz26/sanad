import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workers/src/domain/entities/worker_status.dart';
import 'package:workers/src/domain/entities/worker_type.dart';
import 'package:workers/src/presentation/widgets/workers_filter_bar.dart';

// No EasyLocalization bootstrap — matches services_filter_bar_test.dart's
// convention. `.tr()` falls back to the raw key, so assertions below match
// on the key itself, proving these labels are localization keys, not
// hardcoded strings.

const _surfaceSize = Size(390, 844);

Future<void> _pump(WidgetTester tester, WorkersFilterBar bar) async {
  await tester.binding.setSurfaceSize(_surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: _surfaceSize,
      minTextAdapt: true,
      builder: (_, _) => MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: bar),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('WorkersFilterBar — matches ServicesFilterBar visually (SAN)', () {
    testWidgets('shows the Status and Type placeholders when unset', (
      tester,
    ) async {
      await _pump(
        tester,
        WorkersFilterBar(
          statusFilter: null,
          typeFilter: null,
          onStatusTap: () {},
          onTypeTap: () {},
        ),
      );

      expect(find.text('workers.filters.status'), findsOneWidget);
      expect(find.text('workers.filters.type'), findsOneWidget);
    });

    testWidgets('tapping Status invokes onStatusTap', (tester) async {
      var tapped = false;
      await _pump(
        tester,
        WorkersFilterBar(
          statusFilter: null,
          typeFilter: null,
          onStatusTap: () => tapped = true,
          onTypeTap: () {},
        ),
      );

      await tester.tap(find.text('workers.filters.status'));
      expect(tapped, isTrue);
    });

    testWidgets('tapping Type invokes onTypeTap', (tester) async {
      var tapped = false;
      await _pump(
        tester,
        WorkersFilterBar(
          statusFilter: null,
          typeFilter: null,
          onStatusTap: () {},
          onTypeTap: () => tapped = true,
        ),
      );

      await tester.tap(find.text('workers.filters.type'));
      expect(tapped, isTrue);
    });

    testWidgets(
      'a selected status shows its localized label instead of the '
      'placeholder',
      (tester) async {
        await _pump(
          tester,
          WorkersFilterBar(
            statusFilter: WorkerStatus.active,
            typeFilter: null,
            onStatusTap: () {},
            onTypeTap: () {},
          ),
        );

        expect(find.text('workers.filters.active'), findsOneWidget);
        expect(find.text('workers.filters.status'), findsNothing);
      },
    );

    testWidgets(
      'a selected type shows its localized label instead of the placeholder',
      (tester) async {
        await _pump(
          tester,
          WorkersFilterBar(
            statusFilter: null,
            typeFilter: WorkerType.manager,
            onStatusTap: () {},
            onTypeTap: () {},
          ),
        );

        expect(find.text('workers.add_worker.type_manager'), findsOneWidget);
        expect(find.text('workers.filters.type'), findsNothing);
      },
    );

    testWidgets('inactive status label renders distinctly from active', (
      tester,
    ) async {
      await _pump(
        tester,
        WorkersFilterBar(
          statusFilter: WorkerStatus.inactive,
          typeFilter: null,
          onStatusTap: () {},
          onTypeTap: () {},
        ),
      );

      expect(find.text('workers.filters.inactive'), findsOneWidget);
    });

    testWidgets('worker type label renders distinctly from manager', (
      tester,
    ) async {
      await _pump(
        tester,
        WorkersFilterBar(
          statusFilter: null,
          typeFilter: WorkerType.worker,
          onStatusTap: () {},
          onTypeTap: () {},
        ),
      );

      expect(find.text('workers.add_worker.type_worker'), findsOneWidget);
    });
  });
}
