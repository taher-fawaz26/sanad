import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Help & support links section — Figma `3821:18896`.
class HelpSupportSection extends StatelessWidget {
  const HelpSupportSection({
    super.key,
    this.onContactSupport,
    this.onTermsOfService,
    this.onPrivacyPolicy,
  });

  final VoidCallback? onContactSupport;
  final VoidCallback? onTermsOfService;
  final VoidCallback? onPrivacyPolicy;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final chevron = Icon(
      Icons.chevron_right,
      size: 18,
      color: colors.gray400,
    );

    return AppSectionCard(
      title: 'settings.section_help_support'.tr(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTableRow(
            title: 'settings.contact_support'.tr(),
            trailing: AppTableTrailing.icon,
            trailingIcon: chevron,
            onTap: onContactSupport,
          ),
          const AppDivider(),
          AppTableRow(
            title: 'settings.terms_of_service'.tr(),
            trailing: AppTableTrailing.icon,
            trailingIcon: chevron,
            onTap: onTermsOfService,
          ),
          const AppDivider(),
          AppTableRow(
            title: 'settings.privacy_policy'.tr(),
            trailing: AppTableTrailing.icon,
            trailingIcon: chevron,
            onTap: onPrivacyPolicy,
          ),
        ],
      ),
    );
  }
}
