import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/widgets/bottom_sheets/add_or_change_email_sheet.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/widgets/bottom_sheets/add_or_change_phone_sheet.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/widgets/components/verified_email_field.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/widgets/components/verified_phone_field.dart';
import 'package:shared_ui/shared_ui.dart';

/// Section displaying the organization's contact info (phone + email).
///
/// Pure and prop-driven — [phone]/[email] come from the root
/// `OrganizationProfileEntity` (single source of truth, `businessPhone` /
/// `businessEmail` are only ever non-null once verified). Opens the
/// per-field Add/Change sheets (which run the shared OTP flow) and calls
/// [onRefresh] once a field is verified so the caller can re-pull the root
/// profile.
class ContactInformationSection extends StatelessWidget {
  const ContactInformationSection({
    super.key,
    this.phone,
    this.email,
    this.onRefresh,
  });

  final String? phone;
  final String? email;
  final VoidCallback? onRefresh;

  Future<void> _addOrChangePhone(BuildContext context) async {
    final result = await showAddOrChangePhoneSheet(
      context: context,
      initialPhone: phone,
    );
    if (result == null || !context.mounted) return;
    await _syncBusinessProfileToSession(businessPhone: result);
    onRefresh?.call();
  }

  Future<void> _addOrChangeEmail(BuildContext context) async {
    final result = await showAddOrChangeEmailSheet(
      context: context,
      initialEmail: email,
    );
    if (result == null || !context.mounted) return;
    await _syncBusinessProfileToSession(businessEmail: result);
    onRefresh?.call();
  }

  /// Keeps the session's lightweight `BusinessProviderProfileModel` (read by
  /// the KPI hub / shells) coherent with a business contact change —
  /// `OrganizationSettingsRefreshed` only updates the richer `/settings`
  /// profile this section itself reads from, not the session's copy.
  Future<void> _syncBusinessProfileToSession({
    String? businessEmail,
    String? businessPhone,
  }) async {
    final sessionManager = sl<SessionManager>();
    final current = sessionManager.profile;
    if (current is! BusinessProviderProfileModel) return;

    await sessionManager.setProfile(
      BusinessProviderProfileModel(
        id: current.id,
        isReviewed: current.isReviewed,
        businessName: current.businessName,
        businessEmail: businessEmail ?? current.businessEmail,
        businessPhone: businessPhone ?? current.businessPhone,
        tradeLicenseNumber: current.tradeLicenseNumber,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'settings.section_contact'.tr(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VerifiedPhoneField(
            phone: phone,
            verified: phone != null,
            onAdd: () => _addOrChangePhone(context),
            onChange: () => _addOrChangePhone(context),
          ),
          SizedBox(height: AppSpacing.md),
          VerifiedEmailField(
            email: email,
            verified: email != null,
            onAdd: () => _addOrChangeEmail(context),
            onChange: () => _addOrChangeEmail(context),
          ),
        ],
      ),
    );
  }
}
