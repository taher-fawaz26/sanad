import 'package:app_assets/app_assets.dart';
import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/spacing/responsive_spacing.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/colors/field_tokens.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Figma select / dropdown field — read-only tap target with chevron.
class AppSelectField extends StatelessWidget {
  const AppSelectField({
    required this.label,
    super.key,
    this.value,
    this.hint,
    this.prefix,
    this.onTap,
    this.enabled = true,
    this.showChevron = true,
    this.errorText,
  });

  final String label;
  final String? value;
  final String? hint;
  final Widget? prefix;
  final VoidCallback? onTap;
  final bool enabled;
  final bool showChevron;

  /// When non-null, the field renders with an error border and this
  /// message below it (Figma field error state).
  final String? errorText;

  bool get _hasValue => value != null && value!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final brightness = Theme.of(context).brightness;
    final fieldHeight = responsiveDimension(FieldTokens.fieldHeight);
    final labelGap = responsiveDimension(FieldTokens.labelGap);
    final iconSize = AppDimension.dropdownChevronSize;

    final displayStyle = _hasValue
        ? FieldTokens.valueStyle(
            typography,
            colors,
            brightness,
            enabled: enabled,
          )
        : FieldTokens.hintStyle(
            typography,
            colors,
            brightness,
            enabled: enabled,
          );

    final hasError = errorText != null && errorText!.isNotEmpty;
    final borderColor = hasError
        ? FieldTokens.errorBorder(colors, brightness)
        : FieldTokens.borderDefault(colors, brightness);

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      value: _hasValue ? value : hint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: FieldTokens.labelStyle(typography, colors, brightness),
          ),
          SizedBox(height: labelGap),
          Material(
            color: FieldTokens.background(colors, brightness, enabled: enabled),
            shape: RoundedRectangleBorder(
              borderRadius: FieldTokens.borderRadiusAll(),
              side: BorderSide(
                color: borderColor,
                width: responsiveDimension(FieldTokens.borderWidthDefault),
              ),
            ),
            child: InkWell(
              onTap: enabled ? onTap : null,
              borderRadius: FieldTokens.borderRadiusAll(),
              child: SizedBox(
                height: fieldHeight,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsiveDimension(
                      FieldTokens.horizontalPadding,
                    ),
                  ),
                  child: Row(
                    children: [
                      if (prefix != null) ...[
                        prefix!,
                        SizedBox(width: AppSpacing.sm),
                      ],
                      Expanded(
                        child: Text(
                          _hasValue ? value! : (hint ?? ''),
                          style: displayStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (showChevron) ...[
                        SizedBox(width: AppSpacing.sm),
                        SvgPicture.asset(
                          AppSvgs.chevronDown,
                          package: AppAssets.package,
                          width: iconSize,
                          height: iconSize,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (hasError) ...[
            SizedBox(height: labelGap),
            Text(
              errorText!,
              style: FieldTokens.errorStyle(typography, colors, brightness),
            ),
          ],
        ],
      ),
    );
  }
}
