import 'package:branches/branches.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:organization_settings/src/domain/entities/organization_profile_entity.dart';
import 'package:organization_settings/src/presentation/bloc/organization_settings/organization_settings_bloc.dart';
import 'package:organization_settings/src/presentation/widgets/bottom_sheets/edit_category_bottom_sheet.dart';
import 'package:organization_settings/src/presentation/widgets/bottom_sheets/edit_identity_bottom_sheet.dart';
import 'package:organization_settings/src/presentation/widgets/bottom_sheets/edit_social_profiles_bottom_sheet.dart';
import 'package:organization_settings/src/presentation/widgets/bottom_sheets/edit_working_hours_bottom_sheet.dart';
import 'package:organization_settings/src/presentation/widgets/components/organization_status_badge.dart';
import 'package:organization_settings/src/presentation/widgets/header/organization_header.dart';
import 'package:organization_settings/src/presentation/widgets/sections/business_progress_section.dart';
import 'package:organization_settings/src/presentation/widgets/sections/category_section.dart';
import 'package:organization_settings/src/presentation/widgets/sections/compliance_documents_section.dart';
import 'package:organization_settings/src/presentation/widgets/sections/contact_information_section.dart';
import 'package:organization_settings/src/presentation/widgets/sections/identity_section.dart';
import 'package:organization_settings/src/presentation/widgets/sections/social_profiles_section.dart';
import 'package:organization_settings/src/presentation/widgets/sections/working_hours_section.dart';
import 'package:organization_settings/src/routes/organization_settings_routes.dart';
import 'package:shared_ui/shared_ui.dart';

/// Preview categories until category *editing* is wired to a real backend
/// endpoint (`GET /service-provider/me` only exposes the organization's
/// already-selected categories, not the full catalog to pick from).
const _kPreviewCategories = [
  CategoryOption(id: 'car_service', name: 'Car Service'),
  CategoryOption(id: 'oil_change', name: 'Oil Change'),
  CategoryOption(id: 'brake_inspection', name: 'Brake Inspection'),
  CategoryOption(id: 'tire_rotation', name: 'Tire Rotation'),
  CategoryOption(id: 'battery_check', name: 'Battery Check'),
];

/// General organization settings view-mode page.
///
/// Reads the organization's full settings profile from
/// [OrganizationSettingsBloc] — `GET /service-provider/me` — the single
/// source of truth for every section on this page. Category, social profile,
/// and working hours *editing* remain local/mocked (no PATCH endpoints exist
/// yet); the read-only display always reflects the backend profile until a
/// local edit is made in the current session.
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
  /// Null until the user edits categories locally this session — until then
  /// the read view shows the backend profile's categories.
  Set<String>? _localSelectedCategoryIds;

  /// Null until the user edits social profiles locally this session.
  SocialProfilesData? _localSocialProfiles;

  /// No backend field exists for working hours yet — this stays local/mocked
  /// exactly as before.
  List<WorkingHoursEditEntry> _workingHoursEntries = const [
    WorkingHoursEditEntry(dayId: 'SATURDAY', from: '09:00', to: '18:00'),
    WorkingHoursEditEntry(dayId: 'SUNDAY', from: '09:00', to: '18:00'),
    WorkingHoursEditEntry(dayId: 'MONDAY', from: '09:00', to: '18:00'),
  ];

  List<String> _categoryNames(OrganizationProfileEntity profile) {
    final localIds = _localSelectedCategoryIds;
    if (localIds != null) {
      return _kPreviewCategories
          .where((category) => localIds.contains(category.id))
          .map((category) => category.name)
          .toList();
    }
    return profile.categories.map((category) => category.name).toList();
  }

  SocialProfilesData _socialProfiles(OrganizationProfileEntity profile) {
    final local = _localSocialProfiles;
    if (local != null) return local;

    final social = profile.socialProfiles;
    return SocialProfilesData(
      facebook: social?.facebook,
      tiktok: social?.tiktok,
      instagram: social?.instagram,
      x: social?.x,
      websiteUrl: social?.websiteUrl,
    );
  }

  List<BusinessProgressChecklistItem> _progressChecklist(
    OrganizationProfileEntity profile,
  ) {
    return [
      BusinessProgressChecklistItem(
        label: 'Phone Number',
        completed: profile.businessPhone != null,
      ),
      BusinessProgressChecklistItem(
        label: 'Email Address',
        completed: profile.businessEmail != null,
      ),
      BusinessProgressChecklistItem(
        label: 'Category',
        completed: profile.categories.isNotEmpty,
      ),
      BusinessProgressChecklistItem(
        label: 'Working Hours',
        completed: _workingHoursEntries.isNotEmpty,
      ),
    ];
  }

  OrganizationProfileStatus _headerStatus(
    OrganizationProfileEntity profile,
    bool checklistComplete,
  ) {
    if (profile.isReviewed) return OrganizationProfileStatus.published;
    if (!checklistComplete) return OrganizationProfileStatus.incomplete;
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
          status: _legalDataStatus(
            isExpired: personal.isExpired,
            isExpiringSoon: personal.isExpiringSoon,
          ),
          licenseNumber: personal.idNumber,
          expiryDate: _formatIsoDate(personal.expiryDate),
          countdownText: personal.isExpiringSoon
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
          status: _legalDataStatus(
            isExpired: tradeLicense.isExpired,
            isExpiringSoon: tradeLicense.isExpiringSoon,
          ),
          licenseNumber: tradeLicense.licenseNumber,
          expiryDate: _formatIsoDate(tradeLicense.expiryDate),
          countdownText: tradeLicense.isExpiringSoon
              ? _countdownText(tradeLicense.expiryDate)
              : null,
          onUpdateDocument: _updateLegalDocuments,
        ),
      );
    }

    return entries;
  }

  ComplianceDocumentStatus _legalDataStatus({
    required bool isExpired,
    required bool isExpiringSoon,
  }) {
    if (isExpired) return ComplianceDocumentStatus.expired;
    if (isExpiringSoon) return ComplianceDocumentStatus.expiring;
    return ComplianceDocumentStatus.verified;
  }

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

  Future<void> _editCategories() async {
    final result = await showEditCategoryBottomSheet(
      context: context,
      categories: _kPreviewCategories,
      initialSelectedIds: _localSelectedCategoryIds ?? const {},
    );
    if (result == null || !mounted) return;
    setState(() => _localSelectedCategoryIds = result);
  }

  Future<void> _editSocialProfiles(SocialProfilesData current) async {
    final result = await showEditSocialProfilesBottomSheet(
      context: context,
      initial: current,
    );
    if (result == null || !mounted) return;
    setState(() => _localSocialProfiles = result);
  }

  Future<void> _editWorkingHours() async {
    final result = await showEditWorkingHoursBottomSheet(
      context: context,
      initialEntries: _workingHoursEntries,
    );
    if (result == null || !mounted) return;
    setState(() => _workingHoursEntries = result);
  }

  List<WorkingHoursEntry> get _workingHoursViewEntries => _workingHoursEntries
      .map(
        (entry) => WorkingHoursEntry(
          dayLabel: BranchScheduleFormatter.localizedDay(entry.dayId),
          hoursLabel: BranchScheduleFormatter.formatSlot(
            BranchTimeSlotEntity(from: entry.from, to: entry.to),
          ),
        ),
      )
      .toList();

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

    return BlocBuilder<OrganizationSettingsBloc, OrganizationSettingsState>(
      builder: (context, state) {
        final profile = state.organization?.profile;

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
            if (profile == null && state.status == RequestStatus.loading)
              const AppSliverLoading()
            else if (profile == null && state.status == RequestStatus.failure)
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
            else if (profile != null)
              AppSliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
                sliver: SliverMainAxisGroup(
                  slivers: [
                    AppSliverBox(
                      child: OrganizationHeader(
                        name: profile.businessName,
                        coverUrl: profile.coverImage?.url,
                        logoUrl: profile.profileImage?.url,
                        status: _headerStatus(
                          profile,
                          _progressChecklist(profile).every(
                            (item) => item.completed,
                          ),
                        ),
                      ),
                    ),
                    const AppSliverGap(sectionSpacing),
                    AppSliverBox(
                      child: BusinessProgressSection(
                        completionPercent:
                            ((_progressChecklist(profile)
                                            .where((item) => item.completed)
                                            .length /
                                        _progressChecklist(profile).length) *
                                    100)
                                .round(),
                        items: _progressChecklist(profile),
                      ),
                    ),
                    const AppSliverGap(sectionSpacing),
                    AppSliverBox(
                      child: IdentitySection(
                        onEdit: () =>
                            showEditIdentityBottomSheet(context: context),
                        businessDescription: profile.description,
                      ),
                    ),
                    const AppSliverGap(sectionSpacing),
                    AppSliverBox(
                      child: CategorySection(
                        selectedCategories: _categoryNames(profile),
                        onEdit: _editCategories,
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
                          final social = _socialProfiles(profile);
                          return SocialProfilesSection(
                            onEdit: () => _editSocialProfiles(social),
                            facebook: social.facebook,
                            tiktok: social.tiktok,
                            instagram: social.instagram,
                            x: social.x,
                            websiteUrl: social.websiteUrl,
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
                        entries: _workingHoursViewEntries,
                        onEdit: _editWorkingHours,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
