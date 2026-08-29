import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/widgets/components/settings_verified_field_view.dart';

/// Read-only social profile field for general settings view mode.
///
/// Shows an optional square icon on the left and the URL value to its right.
/// Pass [iconAsset] as `null` for fields with no social icon (e.g. Website URL).
class SettingsSocialFieldView extends StatelessWidget {
  const SettingsSocialFieldView({
    super.key,
    required this.label,
    this.iconAsset,
    this.value,
  });

  final String label;

  /// SVG asset path from [AppSvgs]. `null` renders no icon prefix.
  final String? iconAsset;

  /// Current URL value to display. `null` renders nothing.
  final String? value;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final brightness = Theme.of(context).brightness;

    return SettingsVerifiedFieldView(
      label: label,
      showVerifiedBadge: false,
      // Social profile values (URLs, handles) are inherently LTR: the icon
      // must always sit on the visual left and the value must read
      // left-to-right, regardless of app locale. Only the value row is
      // forced — the surrounding label + section header keep the ambient
      // locale direction. Mirrors the `isLtr` rule the editable social
      // fields opt into on [AppTextField].
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: [
            if (iconAsset != null) ...[
              AppSvgPicture.asset(iconAsset!, width: 24, height: 24),
              SizedBox(width: AppSpacing.sm),
            ],
            if (value != null)
              Expanded(
                child: Text(
                  value!,
                  textDirection: TextDirection.ltr,
                  style: typography.regularNone.copyWith(
                    color: FieldTokens.hintColor(
                      colors,
                      brightness,
                      enabled: true,
                    ),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
