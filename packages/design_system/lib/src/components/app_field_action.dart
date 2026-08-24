import 'package:design_system/src/components/app_field_label.dart';
import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/spacing/responsive_spacing.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/colors/field_tokens.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';

/// Figma location field — labeled input with leading icon and inline action.
class AppFieldAction extends StatelessWidget {
  const AppFieldAction({
    required this.label,
    required this.actionLabel,
    super.key,
    this.value,
    this.hint,
    this.leading,
    this.onActionTap,
    this.onTap,
    this.enabled = true,
    this.isRequired = false,
    this.errorText,
  });

  final String label;
  final String? value;
  final String? hint;
  final Widget? leading;
  final String actionLabel;
  final VoidCallback? onActionTap;
  final VoidCallback? onTap;
  final bool enabled;

  /// When `true`, appends a red `*` after the label.
  final bool isRequired;

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppFieldLabel(label: label, isRequired: isRequired),
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
                    if (leading != null) ...[
                      leading!,
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
                    GestureDetector(
                      onTap: enabled ? onActionTap : null,
                      behavior: HitTestBehavior.opaque,
                      child: Text(
                        actionLabel,
                        style: typography.regularNormal.copyWith(
                          color: colors.link,
                          fontWeight: FontWeight.w400,
                          height: 16 / 16,
                        ),
                      ),
                    ),
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
    );
  }
}
