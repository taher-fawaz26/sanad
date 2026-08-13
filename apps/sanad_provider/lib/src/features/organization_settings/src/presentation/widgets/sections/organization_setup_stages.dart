import 'package:app_assets/app_assets.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/provider_completion_entity.dart';

/// Stable id for one of the four Figma setup-card stages — never the
/// backend's per-item [ProviderCompletionItemId], which is more granular.
enum OrganizationSetupStageId { businessProfile, firstBranch, firstTeam, grow }

/// One row of the "Complete your organization setup" card, derived from
/// [ProviderCompletionEntity.items] — pure data, no widgets/context.
class OrganizationSetupStage {
  const OrganizationSetupStage({
    required this.id,
    required this.titleKey,
    required this.subtitleKey,
    required this.iconAsset,
    required this.completed,
  });

  final OrganizationSetupStageId id;

  /// Localization key for the stage title (not the backend's localized
  /// `label` — the four visual stages don't map 1:1 to backend items).
  final String titleKey;
  final String subtitleKey;

  /// `AppSvgs` path for this stage's icon glyph (Figma `4349:5171`).
  final String iconAsset;
  final bool completed;
}

/// Maps the backend's 7-item completion checklist onto the Figma card's 4
/// visual stages. A stage is complete only when every backend item it
/// aggregates is complete. Matches items by [ProviderCompletionItemId] —
/// never by localized label.
List<OrganizationSetupStage> mapCompletionToStages(
  ProviderCompletionEntity completion,
) {
  bool completedFor(Set<ProviderCompletionItemId> ids) {
    final matching = completion.items.where((item) => ids.contains(item.id));
    return matching.isNotEmpty && matching.every((item) => item.completed);
  }

  return [
    OrganizationSetupStage(
      id: OrganizationSetupStageId.businessProfile,
      titleKey: 'settings.setup_stage_business_profile',
      subtitleKey: 'settings.setup_stage_business_profile_subtitle',
      iconAsset: AppSvgs.call,
      completed: completedFor(const {
        ProviderCompletionItemId.category,
        ProviderCompletionItemId.phone,
        ProviderCompletionItemId.email,
        ProviderCompletionItemId.workingHours,
      }),
    ),
    OrganizationSetupStage(
      id: OrganizationSetupStageId.firstBranch,
      titleKey: 'settings.setup_stage_first_branch',
      subtitleKey: 'settings.setup_stage_first_branch_subtitle',
      iconAsset: AppSvgs.officeBuilding,
      completed: completedFor(const {ProviderCompletionItemId.branches}),
    ),
    OrganizationSetupStage(
      id: OrganizationSetupStageId.firstTeam,
      titleKey: 'settings.setup_stage_first_team',
      subtitleKey: 'settings.setup_stage_first_team_subtitle',
      iconAsset: AppSvgs.userOutline,
      completed: completedFor(const {ProviderCompletionItemId.team}),
    ),
    OrganizationSetupStage(
      id: OrganizationSetupStageId.grow,
      titleKey: 'settings.setup_stage_grow',
      subtitleKey: 'settings.setup_stage_grow_subtitle',
      iconAsset: AppSvgs.trendingUp,
      completed: completedFor(const {ProviderCompletionItemId.services}),
    ),
  ];
}
