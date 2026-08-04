import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:organization_settings/src/presentation/widgets/components/settings_verified_field_view.dart';

/// Read-only email field for general settings view mode.
class SettingsEmailFieldView extends StatelessWidget {
  const SettingsEmailFieldView({
    super.key,
    required this.email,
    this.label,
    this.showVerifiedBadge = true,
  });

  final String email;
  final String? label;
  final bool showVerifiedBadge;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final fieldLabel = label ?? 'settings.email_address'.tr();

    return SettingsVerifiedFieldView(
      label: fieldLabel,
      showVerifiedBadge: showVerifiedBadge,
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          email,
          style: typography.regularNone.copyWith(color: colors.textPrimary),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
