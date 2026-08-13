import 'package:branches/branches.dart'
    show BranchScheduleFormatter, BranchTimeSlotEntity;
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/business_profile_status.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/category_entity.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/legal_data_status.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/organization_profile_entity.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/provider_completion_entity.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/social_profiles_entity.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/working_hours_day_entity.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/bloc/organization_settings/organization_settings_bloc.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/widgets/bottom_sheets/edit_category_bottom_sheet.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/widgets/bottom_sheets/edit_identity_bottom_sheet.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/widgets/bottom_sheets/edit_social_profiles_bottom_sheet.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/widgets/bottom_sheets/edit_working_hours_bottom_sheet.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/widgets/components/organization_status_badge.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/widgets/header/organization_header.dart';
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

final _skeletonCompletion = ProviderCompletionEntity(
  percentage: 40,
  requiredCompleted: 2,
  requiredTotal: 5,
  visibleToCustomers: false,
  items: const [],
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
  const GeneralSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrganizationSettingsBloc>(
      create: (_) =>
          sl<OrganizationSettingsBloc>()
            ..add(const OrganizationSettingsLoaded()),
      child: const _GeneralSettingsView(),
    );
  }
}

class _GeneralSettingsView extends StatefulWidget {
  const _GeneralSettingsView();

  @override
  State<_GeneralSettingsView> createState() => _GeneralSettingsViewState();
}

class _GeneralSettingsViewState extends State<_GeneralSettingsView> {
  List<BusinessProgressChecklistItem> _progressChecklist(
    ProviderCompletionEntity? completion,
  ) {
    final items = completion?.items ?? const [];
    return items
        .map(
          (item) => BusinessProgressChecklistItem(
            label: item.label,
            completed: item.completed,
          ),
        )
        .toList();
  }

  OrganizationProfileStatus _headerStatus(
    OrganizationProfileEntity profile,
    ProviderCompletionEntity? completion,
  ) {
    // expired/suspended are backend-driven and take precedence over the
    // completion-checklist-derived states below — a provider whose profile
    // lapsed or was suspended needs to see that, not "in review".
    if (profile.status == BusinessProfileStatus.expired) {
      return OrganizationProfileStatus.expired;
    }
    if (profile.status == BusinessProfileStatus.suspended) {
      return OrganizationProfileStatus.suspended;
    }
    if (profile.isReviewed) return OrganizationProfileStatus.published;
    if (completion != null && !completion.visibleToCustomers) {
      return OrganizationProfileStatus.incomplete;
    }
    if (completion == null) return OrganizationProfileStatus.incomplete;
    return OrganizationProfileStatus.inReview;
  }

  List<ComplianceDocumentEntry> _complianceDocuments(
    OrganizationProfileEntity profile,
  ) {
    final entries = <ComplianceDocumentEntry>[];

    final personal = profile.personalLegalData;
    if (personal != null) {
      entries.add(
        ComplianceDocumentEntry(
          documentTitle: 'Emirates ID',
          status: _legalDataStatus(personal.status),
          licenseNumber: personal.idNumber,
          expiryDate: _formatIsoDate(personal.expiryDate),
          countdownText: personal.status == LegalDataStatus.expiringSoon
              ? _countdownText(personal.expiryDate)
              : null,
          onUpdateDocument: _updateLegalDocuments,
        ),
      );
    }

    final tradeLicense = profile.tradeLicenseLegalData;
    if (tradeLicense != null) {
      entries.add(
        ComplianceDocumentEntry(
          documentTitle: 'Trade License',
          status: _legalDataStatus(tradeLicense.status),
          licenseNumber: tradeLicense.licenseNumber,
          expiryDate: _formatIsoDate(tradeLicense.expiryDate),
          countdownText: tradeLicense.status == LegalDataStatus.expiringSoon
              ? _countdownText(tradeLicense.expiryDate)
              : null,
          onUpdateDocument: _updateLegalDocuments,
        ),
      );
    }

    return entries;
  }

  ComplianceDocumentStatus _legalDataStatus(LegalDataStatus status) =>
      switch (status) {
        LegalDataStatus.expired => ComplianceDocumentStatus.expired,
        LegalDataStatus.expiringSoon => ComplianceDocumentStatus.expiring,
        LegalDataStatus.verified => ComplianceDocumentStatus.verified,
      };

  String? _formatIsoDate(String? isoDate) {
    if (isoDate == null) return null;
    final date = DateTime.tryParse(isoDate);
    if (date == null) return isoDate;

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String? _countdownText(String? isoDate) {
    final date = DateTime.tryParse(isoDate ?? '');
    if (date == null) return null;

    final days = date.difference(DateTime.now()).inDays;
    if (days <= 0) return 'Expires today';
    return 'In $days days';
  }

  Future<void> _updateLegalDocuments() async {
    final refreshed = await context.push<bool>(
      OrganizationSettingsRoutes.legalDocuments,
    );
    if ((refreshed ?? false) && mounted) {
      context.read<OrganizationSettingsBloc>().add(
        const OrganizationSettingsRefreshed(),
      );
    }
  }

  Future<void> _editDescription(String? currentDescription) async {
    final result = await showEditIdentityBottomSheet(
      context: context,
      initialDescription: currentDescription,
    );
    if (result == null || !mounted) return;
    context.read<OrganizationSettingsBloc>().add(
      OrganizationSettingsDescriptionSaved(result),
    );
  }

  Future<void> _editCategories(
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
    if (result == null || !mounted) return;

    final selectedCategories = catalog
        .where((category) => result.contains(category.id))
        .toList();
    context.read<OrganizationSettingsBloc>().add(
      OrganizationSettingsCategoriesSaved(selectedCategories),
    );
  }

  Future<void> _editSocialProfiles(SocialProfilesData current) async {
    final result = await showEditSocialProfilesBottomSheet(
      context: context,
      initial: current,
    );
    if (result == null || !mounted) return;
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

  Future<void> _editWorkingHours(List<WorkingHoursDayEntity> current) async {
    final entries = <WorkingHoursEditEntry>[
      for (final day in current)
        for (final slot in day.slots)
          WorkingHoursEditEntry(dayId: day.day, from: slot.from, to: slot.to),
    ];

    final result = await showEditWorkingHoursBottomSheet(
      context: context,
      initialEntries: entries,
    );
    if (result == null || !mounted) return;

    final availability = result
        .map(
          (entry) => WorkingHoursDayEntity(
            day: entry.dayId,
            slots: [WorkingHoursSlotEntity(from: entry.from, to: entry.to)],
          ),
        )
        .toList();

    context.read<OrganizationSettingsBloc>().add(
      OrganizationSettingsWorkingHoursSaved(availability),
    );
  }

  List<WorkingHoursEntry> _workingHoursViewEntries(
    List<WorkingHoursDayEntity> availability,
  ) => [
    for (final day in availability)
      for (final slot in day.slots)
        WorkingHoursEntry(
          dayLabel: BranchScheduleFormatter.localizedDay(day.day),
          hoursLabel: BranchScheduleFormatter.formatSlot(
            BranchTimeSlotEntity(from: slot.from, to: slot.to),
          ),
        ),
  ];

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
        if (state.saveFailure != null) {
          showAppErrorSnackbar(
            context: context,
            title: state.saveFailure!.message,
          );
        }
      },
      child: BlocBuilder<OrganizationSettingsBloc, OrganizationSettingsState>(
        builder: (context, state) {
          final isInitialLoad =
              state.organization == null &&
              state.status == RequestStatus.loading;
          // Skeletonize the *real* sliver content, seeded with mock data while
          // loading — never a bespoke skeleton widget.
          final profile = state.organization ?? _skeletonProfile;
          final completion =
              state.completion ?? (isInitialLoad ? _skeletonCompletion : null);

          return AppScrollPage(
            backgroundColor: colors.surface,
            slivers: [
              AppSliverAppBar(
                navBar: AppNavBar(
                  title: 'settings.general_settings'.tr(),
                  showBackButton: true,
                  onLeadingTap: () => context.pop(),
                  trailingAction: AppNavBarTrailingAction.icon,
                  trailing: const Icon(Icons.notifications_outlined),
                  onTrailingTap: () => _showComingSoon(context),
                ),
              ),
              if (state.organization == null &&
                  state.status == RequestStatus.failure)
                AppSliverError(
                  title: 'Something went wrong',
                  description:
                      state.failure?.message ??
                      'Failed to load your organization settings.',
                  retryLabel: 'Retry',
                  onRetry: () => context.read<OrganizationSettingsBloc>().add(
                    const OrganizationSettingsRefreshed(),
                  ),
                )
              else
                AppSliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.md,
                  ),
                  sliver: AppSkeletonizer.sliver(
                    enabled: isInitialLoad,
                    child: SliverMainAxisGroup(
                      slivers: [
                        AppSliverBox(
                          child: OrganizationHeader(
                            name: profile.businessName,
                            coverUrl: profile.coverImage?.url,
                            logoUrl: profile.profileImage?.url,
                            status: _headerStatus(profile, completion),
                            onMediaUpdated: (slot, url) =>
                                context.read<OrganizationSettingsBloc>().add(
                                  OrganizationSettingsMediaUpdated(
                                    slot: slot,
                                    url: url,
                                  ),
                                ),
                          ),
                        ),
                        if (profile.status == BusinessProfileStatus.inReview &&
                            profile.rejectionReason != null) ...[
                          const AppSliverGap(sectionSpacing),
                          AppSliverBox(
                            child: AppAlert(
                              type: AppAlertType.rejected,
                              message: profile.rejectionReason!,
                            ),
                          ),
                        ],
                        const AppSliverGap(sectionSpacing),
                        if (completion != null)
                          AppSliverBox(
                            child: BusinessProgressSection(
                              completionPercent: completion.percentage.round(),
                              items: _progressChecklist(completion),
                              visibleToCustomers: completion.visibleToCustomers,
                              requiredCompleted: completion.requiredCompleted,
                              requiredTotal: completion.requiredTotal,
                            ),
                          ),
                        if (completion != null)
                          const AppSliverGap(sectionSpacing),
                        AppSliverBox(
                          child: IdentitySection(
                            onEdit: () => _editDescription(profile.description),
                            businessDescription: profile.description,
                          ),
                        ),
                        const AppSliverGap(sectionSpacing),
                        AppSliverBox(
                          child: CategorySection(
                            selectedCategories: profile.categories
                                .map((category) => category.name)
                                .toList(),
                            onEdit: () => _editCategories(
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
                            documents: _complianceDocuments(profile),
                          ),
                        ),
                        const AppSliverGap(sectionSpacing),
                        AppSliverBox(
                          child: WorkingHoursSection(
                            entries: _workingHoursViewEntries(
                              state.workingHours,
                            ),
                            onEdit: () => _editWorkingHours(state.workingHours),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
