import 'package:branches/branches.dart' show BranchScheduleFormatter;
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/business_profile_status.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/category_entity.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/organization_profile_entity.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/provider_completion_entity.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/social_profiles_entity.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/working_hours_day_entity.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/bloc/organization_settings/organization_settings_bloc.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/legal_documents/document_scope.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/mappers/organization_settings_view_mappers.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/widgets/bottom_sheets/edit_category_bottom_sheet.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/widgets/bottom_sheets/edit_identity_bottom_sheet.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/widgets/bottom_sheets/edit_social_profiles_bottom_sheet.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/widgets/bottom_sheets/edit_working_hours_bottom_sheet.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/widgets/header/organization_profile_sliver_header.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/widgets/sections/business_progress_section.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/widgets/sections/category_section.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/widgets/sections/compliance_documents_section.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/widgets/sections/contact_information_section.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/widgets/sections/identity_section.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/widgets/sections/social_profiles_section.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/widgets/sections/working_hours_section.dart';
import 'package:sanad_provider/src/features/organization_settings/src/routes/organization_settings_routes.dart';
import 'package:shared_ui/shared_ui.dart';

/// Realistic mocks used only to skeletonize the real sliver content via
/// [AppSkeletonizer.sliver] while the profile loads — no bespoke skeleton
/// layout.
final _skeletonProfile = OrganizationProfileEntity(
  id: 'skeleton',
  categories: const [],
  status: BusinessProfileStatus.inReview,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

const _skeletonCompletion = ProviderCompletionEntity(
  percentage: 40,
  requiredCompleted: 2,
  requiredTotal: 5,
  visibleToCustomers: false,
  items: [],
);

/// General organization settings view-mode page.
///
/// Reads the organization's business profile, working hours, and
/// profile-completion checklist from [OrganizationSettingsBloc] — the single
/// source of truth for every section on this page. Category, description,
/// social-profile, and working-hours edits all go through the bloc, which
/// persists them via the real backend endpoints (`PATCH
/// service-provider/settings`, `PUT service-provider/working-hours`).
class GeneralSettingsPage extends StatelessWidget {
  /// Creates the general settings page.
  const GeneralSettingsPage({super.key, this.isRootTab = false});

  /// Whether this page is mounted as the provider shell's Settings tab
  /// (individual providers) rather than pushed as a child of the KPI hub
  /// (organization providers).
  ///
  /// A root tab is the bottom-nav destination itself — there is no parent
  /// settings screen to return to, so the AppBar shows no back affordance and
  /// never calls `context.pop()` (which would throw `GoError: There is nothing
  /// to pop`). Set by the route builder, not derived inside the widget.
  final bool isRootTab;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrganizationSettingsBloc>(
      create: (_) =>
          sl<OrganizationSettingsBloc>()
            ..add(const OrganizationSettingsLoaded()),
      child: _GeneralSettingsView(isRootTab: isRootTab),
    );
  }
}

class _GeneralSettingsView extends StatelessWidget {
  const _GeneralSettingsView({required this.isRootTab});

  final bool isRootTab;

  Future<void> _updateLegalDocument(
    BuildContext context,
    DocumentScope scope,
  ) async {
    final refreshed = await context.push<bool>(
      OrganizationSettingsRoutes.legalDocuments,
      extra: scope,
    );
    if ((refreshed ?? false) && context.mounted) {
      context.read<OrganizationSettingsBloc>().add(
        const OrganizationSettingsRefreshed(),
      );
    }
  }

  Future<void> _editDescription(
    BuildContext context,
    String? currentDescription,
  ) async {
    // Prefer the last-attempted text over the persisted description so a
    // user reopening the sheet after a failed save (SAN-567) doesn't lose
    // what they typed — the sheet's own TextEditingController was disposed
    // the moment the sheet popped, so the draft must come from bloc state.
    final bloc = context.read<OrganizationSettingsBloc>();
    final result = await showEditIdentityBottomSheet(
      context: context,
      initialDescription: bloc.state.pendingDescription ?? currentDescription,
    );
    if (result == null || !context.mounted) return;
    bloc.add(OrganizationSettingsDescriptionSaved(result));
  }

  Future<void> _editCategories(
    BuildContext context,
    List<CategoryEntity> catalog,
    List<CategoryEntity> selected,
  ) async {
    final result = await showEditCategoryBottomSheet(
      context: context,
      categories: catalog
          .map(
            (category) => CategoryOption(id: category.id, name: category.name),
          )
          .toList(),
      initialSelectedIds: selected.map((category) => category.id).toSet(),
    );
    if (result == null || !context.mounted) return;

    final selectedCategories = catalog
        .where((category) => result.contains(category.id))
        .toList();
    context.read<OrganizationSettingsBloc>().add(
      OrganizationSettingsCategoriesSaved(selectedCategories),
    );
  }

  Future<void> _editSocialProfiles(
    BuildContext context,
    SocialProfilesData current,
  ) async {
    final result = await showEditSocialProfilesBottomSheet(
      context: context,
      initial: current,
    );
    if (result == null || !context.mounted) return;
    context.read<OrganizationSettingsBloc>().add(
      OrganizationSettingsSocialProfilesSaved(
        SocialProfilesEntity(
          facebook: result.facebook,
          tiktok: result.tiktok,
          instagram: result.instagram,
          x: result.x,
          websiteUrl: result.websiteUrl,
        ),
      ),
    );
  }

  Future<void> _editWorkingHours(
    BuildContext context,
    List<WorkingHoursDayEntity> current,
  ) async {
    // The edit sheet's cubit is already day-grouped and keeps the draft
    // normalized (merged/sorted) after every add/delete (SAN-573), so the
    // result can be dispatched as-is — no flattening/regrouping step needed
    // here.
    final result = await showEditWorkingHoursBottomSheet(
      context: context,
      initialDays: current,
    );
    if (result == null || !context.mounted) return;

    context.read<OrganizationSettingsBloc>().add(
      OrganizationSettingsWorkingHoursSaved(result),
    );
  }

  void _showComingSoon(BuildContext context) {
    showAppSnackbar(
      context: context,
      title: 'settings.coming_soon'.tr(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    const sectionSpacing = 16.0;

    return MutationListener<
      OrganizationSettingsBloc,
      OrganizationSettingsState
    >(
      status: (state) => state.saveStatus,
      title: (context) => 'settings.saving_title'.tr(),
      onFailure: (context, state) {
        final failure = state.saveFailure;
        if (failure == null) return;
        showAppErrorSnackbar(
          context: context,
          title: _saveFailureMessage(context, failure),
        );
      },
      child: BlocBuilder<OrganizationSettingsBloc, OrganizationSettingsState>(
        buildWhen: (previous, current) =>
            previous.status != current.status ||
            previous.organization != current.organization ||
            previous.failure != current.failure ||
            previous.workingHours != current.workingHours ||
            previous.completion != current.completion ||
            previous.categoryCatalog != current.categoryCatalog,
        builder: (context, state) {
          final isInitialLoad =
              state.organization == null &&
              state.status == RequestStatus.loading;
          // Skeletonize the *real* sliver content, seeded with mock data while
          // loading — never a bespoke skeleton widget.
          final profile = state.organization ?? _skeletonProfile;
          final completion =
              state.completion ?? (isInitialLoad ? _skeletonCompletion : null);
          final localeName = context.locale.toString();
          final now = DateTime.now();

          return AppScrollPage(
            backgroundColor: colors.surface,
            slivers: [
              AppSliverAppBar(
                navBar: AppNavBar(
                  title: 'settings.general_settings'.tr(),
                  showBackButton: !isRootTab,
                  onLeadingTap: isRootTab ? null : () => context.pop(),
                  trailingAction: AppNavBarTrailingAction.icon,
                  trailing: const Icon(Icons.notifications_outlined),
                  onTrailingTap: () => _showComingSoon(context),
                ),
              ),
              if (state.organization == null &&
                  state.status == RequestStatus.failure)
                AppSliverError(
                  title: 'settings.load_error_title'.tr(),
                  description:
                      state.failure?.localizedMessage() ??
                      'settings.load_error_description'.tr(),
                  retryLabel: 'common.retry'.tr(),
                  onRetry: () => context.read<OrganizationSettingsBloc>().add(
                    const OrganizationSettingsRefreshed(),
                  ),
                )
              else ...[
                // Facebook-style collapsing identity header — a pinned
                // SliverPersistentHeader that collapses continuously on scroll.
                // Kept outside the skeletonizer group below: it renders its own
                // cover/avatar/name shimmer via `isLoading`.
                OrganizationProfileSliverHeader(
                  name: profile.businessName,
                  coverUrl: profile.coverImage?.url,
                  logoUrl: profile.profileImage?.url,
                  status: organizationHeaderStatus(profile, completion),
                  isLoading: isInitialLoad,
                  onMediaUpdated: (slot, url) =>
                      context.read<OrganizationSettingsBloc>().add(
                        OrganizationSettingsMediaUpdated(slot: slot, url: url),
                      ),
                ),
                AppSliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.md,
                  ),
                  sliver: AppSkeletonizer.sliver(
                    enabled: isInitialLoad,
                    child: SliverMainAxisGroup(
                      slivers: [
                        if (profile.status == BusinessProfileStatus.inReview &&
                            profile.rejectionReason != null) ...[
                          AppSliverBox(
                            child: AppAlert(
                              type: AppAlertType.rejected,
                              message: profile.rejectionReason!,
                            ),
                          ),
                          const AppSliverGap(sectionSpacing),
                        ],
                        if (completion != null)
                          AppSliverBox(
                            child: BusinessProgressSection(
                              completionPercent: completion.percentage.round(),
                              items: businessProgressChecklist(completion),
                              visibleToCustomers: completion.visibleToCustomers,
                              requiredCompleted: completion.requiredCompleted,
                              requiredTotal: completion.requiredTotal,
                            ),
                          ),
                        if (completion != null)
                          const AppSliverGap(sectionSpacing),
                        AppSliverBox(
                          child: IdentitySection(
                            onEdit: () =>
                                _editDescription(context, profile.description),
                            businessDescription: profile.description,
                          ),
                        ),
                        const AppSliverGap(sectionSpacing),
                        AppSliverBox(
                          child: CategorySection(
                            selectedCategories: selectedCategoryNames(
                              profile.categories,
                              state.categoryCatalog,
                            ),
                            onEdit: () => _editCategories(
                              context,
                              state.categoryCatalog,
                              profile.categories,
                            ),
                          ),
                        ),
                        const AppSliverGap(sectionSpacing),
                        AppSliverBox(
                          child: ContactInformationSection(
                            phone: profile.businessPhone,
                            email: profile.businessEmail,
                            onRefresh: () =>
                                context.read<OrganizationSettingsBloc>().add(
                                  const OrganizationSettingsRefreshed(),
                                ),
                          ),
                        ),
                        const AppSliverGap(sectionSpacing),
                        AppSliverBox(
                          child: Builder(
                            builder: (context) {
                              final social = profile.socialProfiles;
                              return SocialProfilesSection(
                                onEdit: () => _editSocialProfiles(
                                  context,
                                  SocialProfilesData(
                                    facebook: social?.facebook,
                                    tiktok: social?.tiktok,
                                    instagram: social?.instagram,
                                    x: social?.x,
                                    websiteUrl: social?.websiteUrl,
                                  ),
                                ),
                                facebook: social?.facebook,
                                tiktok: social?.tiktok,
                                instagram: social?.instagram,
                                x: social?.x,
                                websiteUrl: social?.websiteUrl,
                              );
                            },
                          ),
                        ),
                        const AppSliverGap(sectionSpacing),
                        AppSliverBox(
                          child: ComplianceDocumentsSection(
                            documents: complianceDocumentEntries(
                              profile: profile,
                              localeName: localeName,
                              now: now,
                              onUpdateEmiratesId: () => _updateLegalDocument(
                                context,
                                DocumentScope.emiratesId,
                              ),
                              onUpdateTradeLicense: () => _updateLegalDocument(
                                context,
                                DocumentScope.tradeLicense,
                              ),
                            ),
                          ),
                        ),
                        // Owner-only (RBAC Phase 7G) — a worker/manager's
                        // Settings tab is this same page, and
                        // `service-provider/working-hours` 403s for them
                        // (finding F1); the bloc leaves `workingHours` empty
                        // for a non-owner rather than fetching it, so
                        // rendering this section would misleadingly read as
                        // "no hours configured" instead of simply absent.
                        if (context
                            .read<OrganizationSettingsBloc>()
                            .isOwner) ...[
                          const AppSliverGap(sectionSpacing),
                          AppSliverBox(
                            child: WorkingHoursSection(
                              groups: workingHoursDayGroups(
                                state.workingHours,
                                localeName: localeName,
                              ),
                              onEdit: () => _editWorkingHours(
                                context,
                                state.workingHours,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Resolves the localized save-error message. Recognises the defensive
/// save-time working-hours overlap (SAN-573) via
/// [workingHoursOverlapFailureCode] and formats it using the day/from/to
/// stashed on the failure metadata; otherwise falls back to the standard
/// [Failure.localizedMessage] behavior.
String _saveFailureMessage(BuildContext context, Failure failure) {
  if (failure.code == workingHoursOverlapFailureCode) {
    final meta = failure.metadata ?? const <String, dynamic>{};
    final dayId = meta['dayId'] as String?;
    final from = meta['from'] as String?;
    final to = meta['to'] as String?;
    if (dayId != null && from != null && to != null) {
      final locale = context.locale.toString();
      return workingHoursOverlapMessageKey.tr(
        namedArgs: {
          'day': BranchScheduleFormatter.localizedDay(dayId),
          'from': BranchScheduleFormatter.formatTime(from, locale: locale),
          'to': BranchScheduleFormatter.formatTime(to, locale: locale),
        },
      );
    }
  }
  return failure.localizedMessage();
}
