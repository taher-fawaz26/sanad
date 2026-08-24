import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_provider/src/features/home/src/domain/entities/provider_statistic_entity.dart';
import 'package:sanad_provider/src/features/home/src/presentation/widgets/home_statistics_grid.dart';
import 'package:testing/testing.dart';

void main() {
  const statistics = [
    ProviderStatisticEntity(
      key: 'branches',
      name: 'Branches',
      icon: 'fa-solid fa-store',
      value: 4,
    ),
    ProviderStatisticEntity(
      key: 'workers',
      name: 'Team Members',
      icon: 'fa-solid fa-users',
      value: 12,
    ),
  ];

  testWidgets('renders one tile per statistic with its value and label', (
    tester,
  ) async {
    await pumpDsWidget(
      tester,
      const Scaffold(body: HomeStatisticsGrid(statistics: statistics)),
    );

    expect(find.text('4'), findsOneWidget);
    expect(find.text('Branches'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('Team Members'), findsOneWidget);
    expect(find.byType(FaIcon), findsNWidgets(2));
  });

  testWidgets('resolves the backend icon string to a real Font Awesome icon', (
    tester,
  ) async {
    await pumpDsWidget(
      tester,
      const Scaffold(body: HomeStatisticsGrid(statistics: statistics)),
    );

    final icons = tester
        .widgetList<FaIcon>(find.byType(FaIcon))
        .map((icon) => icon.icon)
        .toList();

    expect(icons, contains(FontAwesomeIcons.solidStore.data));
    expect(icons, contains(FontAwesomeIcons.solidUsers.data));
  });

  testWidgets('falls back safely when the backend icon is unresolvable', (
    tester,
  ) async {
    const unresolvable = [
      ProviderStatisticEntity(
        key: 'branches',
        name: 'Branches',
        icon: 'fa-duotone fa-clock',
        value: 4,
      ),
    ];

    await pumpDsWidget(
      tester,
      const Scaffold(body: HomeStatisticsGrid(statistics: unresolvable)),
    );

    expect(tester.takeException(), isNull);
    expect(
      tester.widget<FaIcon>(find.byType(FaIcon)).icon,
      FontAwesomeIcons.solidCircleQuestion.data,
    );
  });

  testWidgets('renders nothing when there are no statistics', (
    tester,
  ) async {
    await pumpDsWidget(
      tester,
      const Scaffold(body: HomeStatisticsGrid(statistics: [])),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(FaIcon), findsNothing);
  });
}
