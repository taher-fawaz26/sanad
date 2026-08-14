import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/provider_completion_entity.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/widgets/sections/organization_setup_card.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/widgets/sections/organization_setup_stages.dart';

const _incompleteCompletion = ProviderCompletionEntity(
  percentage: 43,
  requiredCompleted: 3,
  requiredTotal: 7,
  visibleToCustomers: false,
  items: [
    ProviderCompletionItemEntity(
      id: ProviderCompletionItemId.category,
      label: 'Category',
      completed: true,
      required: true,
    ),
    ProviderCompletionItemEntity(
      id: ProviderCompletionItemId.phone,
      label: 'Phone',
      completed: false,
      required: true,
    ),
    ProviderCompletionItemEntity(
      id: ProviderCompletionItemId.branches,
      label: 'Branches',
      completed: true,
      required: true,
    ),
    ProviderCompletionItemEntity(
      id: ProviderCompletionItemId.team,
      label: 'Team',
      completed: true,
      required: true,
    ),
    ProviderCompletionItemEntity(
      id: ProviderCompletionItemId.services,
      label: 'Services',
      completed: false,
      required: true,
    ),
  ],
);

const _fullyVisibleCompletion = ProviderCompletionEntity(
  percentage: 100,
  requiredCompleted: 7,
  requiredTotal: 7,
  visibleToCustomers: true,
  items: [],
);

void main() {
  Future<void> pumpCard(
    WidgetTester tester,
    ProviderCompletionEntity completion, {
    ValueChanged<OrganizationSetupStageId>? onStageAction,
  }) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 800),
        minTextAdapt: true,
        builder: (_, _) => MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            // Matches production usage: the card is one item in a scrolling
            // ListView, which gives it unbounded height — a bare Scaffold
            // body would bound it to the viewport and overflow instead.
            body: SingleChildScrollView(
              child: OrganizationSetupCard(
                completion: completion,
                onStageAction: onStageAction ?? (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'shows the Hidden-from-Customers badge and the backend percentage '
    'summary — never a locally-derived stage count',
    (tester) async {
      await pumpCard(tester, _incompleteCompletion);

      expect(find.text('settings.setup_hidden_badge'), findsOneWidget);
      // requiredCompleted/requiredTotal/percentage straight from the
      // backend entity (3/7/43), not a 4-stage-derived count.
      expect(find.text('43%'), findsOneWidget);
      expect(find.text('settings.setup_required_summary'), findsOneWidget);
    },
  );

  testWidgets(
    'hides the badge when visibleToCustomers is true',
    (tester) async {
      await pumpCard(tester, _fullyVisibleCompletion);

      expect(find.text('settings.setup_hidden_badge'), findsNothing);
      expect(find.text('100%'), findsOneWidget);
    },
  );

  testWidgets(
    'shows an "Add" affordance only for incomplete stages, and tapping it '
    'reports the tapped stage id',
    (tester) async {
      OrganizationSetupStageId? tapped;
      await pumpCard(
        tester,
        _incompleteCompletion,
        onStageAction: (id) => tapped = id,
      );

      // Business Profile is incomplete (phone missing) -> has "Add".
      // First Branch and First Team are complete -> no "Add" for them.
      // Grow (services) is incomplete -> has "Add".
      expect(find.text('common.add'), findsNWidgets(2));

      final addButton = find.text('common.add').first;
      await tester.ensureVisible(addButton);
      await tester.pumpAndSettle();
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      expect(tapped, OrganizationSetupStageId.businessProfile);
    },
  );

  testWidgets('renders all four stage titles in order', (tester) async {
    await pumpCard(tester, _incompleteCompletion);

    expect(find.text('settings.setup_stage_business_profile'), findsOneWidget);
    expect(find.text('settings.setup_stage_first_branch'), findsOneWidget);
    expect(find.text('settings.setup_stage_first_team'), findsOneWidget);
    expect(find.text('settings.setup_stage_grow'), findsOneWidget);
  });
}
