import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:organization_settings/src/presentation/widgets/bottom_sheets/edit_category_bottom_sheet.dart';
import 'package:organization_settings/src/presentation/widgets/bottom_sheets/edit_contact_information_bottom_sheet.dart';
import 'package:organization_settings/src/presentation/widgets/bottom_sheets/edit_identity_bottom_sheet.dart';
import 'package:organization_settings/src/presentation/widgets/header/organization_header.dart';
import 'package:organization_settings/src/presentation/widgets/sections/category_section.dart';
import 'package:organization_settings/src/presentation/widgets/sections/compliance_documents_section.dart';
import 'package:organization_settings/src/presentation/widgets/sections/contact_information_section.dart';
import 'package:organization_settings/src/presentation/widgets/sections/identity_section.dart';
import 'package:organization_settings/src/presentation/widgets/sections/social_profiles_section.dart';
import 'package:organization_settings/src/presentation/widgets/sections/working_hours_section.dart';

/// Preview categories until the categories API is wired in a future PR.
const _kPreviewCategories = [
  CategoryOption(id: 'car_service', name: 'Car Service'),
  CategoryOption(id: 'oil_change', name: 'Oil Change'),
  CategoryOption(id: 'brake_inspection', name: 'Brake Inspection'),
  CategoryOption(id: 'tire_rotation', name: 'Tire Rotation'),
  CategoryOption(id: 'battery_check', name: 'Battery Check'),
];

/// General organization settings view-mode page.
///
/// Read-only composition of independently editable sections. Each section's
/// edit flow will be implemented in future PRs via dedicated bottom sheets.
class GeneralSettingsPage extends StatefulWidget {
  /// Creates the general settings page scaffold.
  const GeneralSettingsPage({super.key});

  @override
  State<GeneralSettingsPage> createState() => _GeneralSettingsPageState();
}

class _GeneralSettingsPageState extends State<GeneralSettingsPage> {
  Set<String> _selectedCategoryIds = {
    'car_service',
    'oil_change',
    'brake_inspection',
  };

  String _phone = '50 123 4567';
  String _email = 'ops@sanad.ae';

  List<String> get _selectedCategoryNames => _kPreviewCategories
      .where((category) => _selectedCategoryIds.contains(category.id))
      .map((category) => category.name)
      .toList();

  Future<void> _editCategories() async {
    final result = await showEditCategoryBottomSheet(
      context: context,
      categories: _kPreviewCategories,
      initialSelectedIds: _selectedCategoryIds,
    );
    if (result == null || !mounted) return;
    setState(() => _selectedCategoryIds = result);
  }

  Future<void> _editContactInformation() async {
    final result = await showEditContactInformationBottomSheet(
      context: context,
      initialPhone: _phone,
      initialEmail: _email,
    );
    if (result == null || !mounted) return;
    setState(() {
      _phone = result.phone;
      _email = result.email;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final sectionSpacing = AppSpacing.lg;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppNavBar(
        title: 'settings.general_settings'.tr(),
        showBackButton: true,
        onLeadingTap: () => context.pop(),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.md,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const OrganizationHeader(),
                SizedBox(height: sectionSpacing),
                IdentitySection(
                  onEdit: () => showEditIdentityBottomSheet(context: context),
                  businessDescription:
                      'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
                ),
                SizedBox(height: sectionSpacing),
                CategorySection(
                  selectedCategories: _selectedCategoryNames,
                  onEdit: _editCategories,
                ),
                SizedBox(height: sectionSpacing),
                ContactInformationSection(
                  phone: _phone,
                  email: _email,
                  onEdit: _editContactInformation,
                ),
                SizedBox(height: sectionSpacing),
                SocialProfilesSection(
                  onEdit: () {},
                  facebook: 'https://www.sanad.ae',
                  tiktok: 'sanad.ae',
                  instagram: 'sanad.ae',
                  twitter: 'sanad.ae',
                  websiteUrl: 'https://www.sanad.ae',
                ),
                SizedBox(height: sectionSpacing),
                ComplianceDocumentsSection(
                  documents: const [
                    ComplianceDocumentEntry(
                      documentTitle: 'Trade License',
                      status: ComplianceDocumentStatus.verified,
                      licenseNumber: 'TL-2024-123456',
                      expiryDate: '15 May 2026',
                    ),
                    ComplianceDocumentEntry(
                      documentTitle: 'Emirates ID',
                      status: ComplianceDocumentStatus.expiring,
                      licenseNumber: 'CN-1234567',
                      expiryDate: '15 May 2026',
                      countdownText: 'In 19 days',
                    ),
                    ComplianceDocumentEntry(
                      documentTitle: 'Trade License',
                      status: ComplianceDocumentStatus.expired,
                      licenseNumber: 'TL-2023-999',
                      expiryDate: '15 Apr 2026',
                    ),
                    ComplianceDocumentEntry(
                      documentTitle: 'Emirates ID',
                      status: ComplianceDocumentStatus.underReview,
                      licenseNumber: 'CN-7654321',
                      expiryDate: '15 Apr 2026',
                    ),
                    ComplianceDocumentEntry(
                      documentTitle: 'Trade License',
                      status: ComplianceDocumentStatus.rejected,
                      licenseNumber: 'TL-2024-001',
                      expiryDate: '15 Apr 2026',
                    ),
                  ],
                ),
                SizedBox(height: sectionSpacing),
                WorkingHoursSection(
                  entries: [
                    WorkingHoursEntry(
                      dayLabel: 'branches.add_branch.days.saturday'.tr(),
                      hoursLabel: '9:00 AM – 6:00 PM',
                    ),
                    WorkingHoursEntry(
                      dayLabel: 'branches.add_branch.days.sunday'.tr(),
                      hoursLabel: '9:00 AM – 6:00 PM',
                    ),
                    WorkingHoursEntry(
                      dayLabel: 'branches.add_branch.days.monday'.tr(),
                      hoursLabel: '9:00 AM – 6:00 PM',
                    ),
                  ],
                  onEdit: () {},
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
