import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:organization_settings/src/presentation/widgets/components/settings_email_field_view.dart';
import 'package:organization_settings/src/presentation/widgets/components/settings_phone_field_view.dart';
import 'package:organization_settings/src/presentation/widgets/components/settings_section_card.dart';

/// View-mode section displaying contact information fields (phone + email).
///
/// Both fields show a verified badge next to their label. The phone field
/// includes a UAE flag prefix and a tappable "Change" link.
class ContactInformationSection extends StatelessWidget {
  const ContactInformationSection({
    super.key,
    this.phone,
    this.email,
    this.onEdit,
    this.onChangePhone,
  });

  final String? phone;
  final String? email;
  final VoidCallback? onEdit;
  final VoidCallback? onChangePhone;

  @override
  Widget build(BuildContext context) {
    return SettingsSectionCard(
      title: 'settings.section_contact'.tr(),
      onEdit: onEdit,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingsPhoneFieldView(
            phone: phone ?? '50 123 4567',
            onChangeTap: onChangePhone,
          ),
          SizedBox(height: AppSpacing.md),
          SettingsEmailFieldView(
            email: email ?? 'ops@sanad.ae',
          ),
        ],
      ),
    );
  }
}
