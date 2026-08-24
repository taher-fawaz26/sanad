import 'package:branches/branches.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_provider/src/features/home/src/domain/entities/provider_statistic_entity.dart';
import 'package:sanad_provider/src/features/home/src/presentation/widgets/home_statistics_grid.dart';
import 'package:testing/testing.dart';
import 'package:workers/workers.dart';

class _FakePage extends StatelessWidget {
  const _FakePage(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Scaffold(body: Text(label));
}

const _homeRoute = '/home';

Future<void> _pumpGrid(
  WidgetTester tester,
  List<ProviderStatisticEntity> statistics,
) async {
  final router = GoRouter(
    initialLocation: _homeRoute,
    routes: [
      GoRoute(
        path: _homeRoute,
        builder: (context, state) =>
            Scaffold(body: HomeStatisticsGrid(statistics: statistics)),
      ),
      GoRoute(
        path: BranchRoutes.list,
        builder: (context, state) => const _FakePage('branches-list'),
      ),
      GoRoute(
        path: WorkerRoutes.list,
        builder: (context, state) => const _FakePage('workers-list'),
      ),
    ],
  );

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: testDesignSize,
      minTextAdapt: true,
      builder: (_, _) =>
          MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('tapping a card with a known key navigates to its screen', (
    tester,
  ) async {
    await _pumpGrid(tester, const [
      ProviderStatisticEntity(key: 'branches', name: 'Branches', value: 4),
    ]);

    await tester.tap(find.text('Branches'));
    await tester.pumpAndSettle();

    expect(find.text('branches-list'), findsOneWidget);
  });

  testWidgets('a second known key navigates to its own screen', (
    tester,
  ) async {
    await _pumpGrid(tester, const [
      ProviderStatisticEntity(key: 'workers', name: 'Team Members', value: 12),
    ]);

    await tester.tap(find.text('Team Members'));
    await tester.pumpAndSettle();

    expect(find.text('workers-list'), findsOneWidget);
  });

  testWidgets('a card with an unrecognized key is not tappable', (
    tester,
  ) async {
    await _pumpGrid(tester, const [
      ProviderStatisticEntity(
        key: 'totalRequests',
        name: 'Total Requests',
        value: 128,
      ),
    ]);

    await tester.tap(find.text('Total Requests'));
    await tester.pumpAndSettle();

    // Still on the home route — no destination exists for this key.
    expect(find.text('Total Requests'), findsOneWidget);
    expect(find.text('branches-list'), findsNothing);
    expect(find.text('workers-list'), findsNothing);
  });
}
