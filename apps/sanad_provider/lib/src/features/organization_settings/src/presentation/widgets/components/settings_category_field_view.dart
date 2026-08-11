import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Read-only category field for general settings view mode.
///
/// Mimics the Figma select field appearance without tap handling. Selected
/// categories render as pill chips below the field.
class SettingsCategoryFieldView extends StatelessWidget {
  const SettingsCategoryFieldView({
    super.key,
    this.selectedCategories = const [],
  });

  final List<String> selectedCategories;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final brightness = Theme.of(context).brightness;
    final fieldHeight = responsiveDimension(FieldTokens.fieldHeight);
    final labelGap = responsiveDimension(FieldTokens.labelGap);
    final iconSize = AppDimension.dropdownChevronSize;
    final hintStyle = FieldTokens.hintStyle(
      typography,
      colors,
      brightness,
      enabled: true,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppFieldLabel(
          label: 'settings.section_category'.tr(),
          isRequired: true,
        ),
        SizedBox(height: labelGap),
        Container(
          height: fieldHeight,
          padding: EdgeInsets.symmetric(
            horizontal: responsiveDimension(FieldTokens.horizontalPadding),
          ),
          decoration: ShapeDecoration(
            color: FieldTokens.background(colors, brightness, enabled: true),
            shape: RoundedRectangleBorder(
              borderRadius: FieldTokens.borderRadiusAll(),
              side: BorderSide(
                color: FieldTokens.borderDefault(colors, brightness),
                width: responsiveDimension(FieldTokens.borderWidthDefault),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'settings.select_category'.tr(),
                  style: hintStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              AppSvgPicture.asset(
                AppSvgs.chevronDown,
                width: iconSize,
                height: iconSize,
              ),
            ],
          ),
        ),
        if (selectedCategories.isNotEmpty) ...[
          SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final category in selectedCategories)
                AppChip(label: category),
            ],
          ),
        ],
      ],
    );
  }
}
