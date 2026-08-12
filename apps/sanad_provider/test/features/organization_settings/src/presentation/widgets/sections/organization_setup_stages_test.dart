import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/provider_completion_entity.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/widgets/sections/organization_setup_stages.dart';

ProviderCompletionItemEntity _item(
  ProviderCompletionItemId id, {
  required bool completed,
}) => ProviderCompletionItemEntity(
  id: id,
  label: id.name,
  completed: completed,
  required: true,
);

void main() {
  group('mapCompletionToStages', () {
    test(
      'Business Profile is complete only when all four backend items are',
      () {
        final allComplete = ProviderCompletionEntity(
          percentage: 100,
          requiredCompleted: 4,
          requiredTotal: 7,
          visibleToCustomers: false,
          items: [
            _item(ProviderCompletionItemId.category, completed: true),
            _item(ProviderCompletionItemId.phone, completed: true),
            _item(ProviderCompletionItemId.email, completed: true),
            _item(ProviderCompletionItemId.workingHours, completed: true),
          ],
        );

        final oneMissing = ProviderCompletionEntity(
          percentage: 43,
          requiredCompleted: 3,
          requiredTotal: 7,
          visibleToCustomers: false,
          items: [
            _item(ProviderCompletionItemId.category, completed: true),
            _item(ProviderCompletionItemId.phone, completed: true),
            _item(ProviderCompletionItemId.email, completed: true),
            _item(ProviderCompletionItemId.workingHours, completed: false),
          ],
        );

        bool businessProfileCompleted(ProviderCompletionEntity c) =>
            mapCompletionToStages(c)
                .firstWhere(
                  (s) => s.id == OrganizationSetupStageId.businessProfile,
                )
                .completed;

        expect(businessProfileCompleted(allComplete), isTrue);
        expect(businessProfileCompleted(oneMissing), isFalse);
      },
    );

    test('branches/team/services map 1:1 to their backend item', () {
      final completion = ProviderCompletionEntity(
        percentage: 86,
        requiredCompleted: 6,
        requiredTotal: 7,
        visibleToCustomers: false,
        items: [
          _item(ProviderCompletionItemId.category, completed: true),
          _item(ProviderCompletionItemId.phone, completed: true),
          _item(ProviderCompletionItemId.email, completed: true),
          _item(ProviderCompletionItemId.workingHours, completed: true),
          _item(ProviderCompletionItemId.branches, completed: true),
          _item(ProviderCompletionItemId.team, completed: true),
          _item(ProviderCompletionItemId.services, completed: false),
        ],
      );

      final stages = mapCompletionToStages(completion);

      expect(
        stages
            .firstWhere((s) => s.id == OrganizationSetupStageId.firstBranch)
            .completed,
        isTrue,
      );
      expect(
        stages
            .firstWhere((s) => s.id == OrganizationSetupStageId.firstTeam)
            .completed,
        isTrue,
      );
      expect(
        stages
            .firstWhere((s) => s.id == OrganizationSetupStageId.grow)
            .completed,
        isFalse,
      );
    });

    test('a stage with no matching backend item is treated as incomplete', () {
      const completion = ProviderCompletionEntity(
        percentage: 0,
        requiredCompleted: 0,
        requiredTotal: 7,
        visibleToCustomers: false,
        items: [],
      );

      final stages = mapCompletionToStages(completion);

      expect(stages, everyElement(isA<OrganizationSetupStage>()));
      expect(stages.every((s) => !s.completed), isTrue);
    });

    test(
      'returns the four stages in fixed order: business profile, branch, '
      'team, grow',
      () {
        const completion = ProviderCompletionEntity(
          percentage: 0,
          requiredCompleted: 0,
          requiredTotal: 7,
          visibleToCustomers: false,
          items: [],
        );

        final ids = mapCompletionToStages(completion).map((s) => s.id).toList();

        expect(ids, [
          OrganizationSetupStageId.businessProfile,
          OrganizationSetupStageId.firstBranch,
          OrganizationSetupStageId.firstTeam,
          OrganizationSetupStageId.grow,
        ]);
      },
    );
  });
}
