import 'package:app_assets/app_assets.dart';
import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/spacing/responsive_spacing.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/colors/field_tokens.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Figma phone field — country flag prefix + phone number input.
class AppPhoneField extends StatelessWidget {
  const AppPhoneField({
    required this.label,
    super.key,
    this.controller,
    this.hint,
    this.onChanged,
    this.enabled = true,
    this.countryFlagAsset = AppSvgs.flagAe,
    this.onCountryTap,
    this.errorText,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final String countryFlagAsset;
  final VoidCallback? onCountryTap;
  final String? errorText;

  bool get _hasError => errorText != null && errorText!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final brightness = Theme.of(context).brightness;
    final fieldHeight = responsiveDimension(FieldTokens.fieldHeight);
    final labelGap = responsiveDimension(FieldTokens.labelGap);
    final iconSize = AppDimension.iconLg;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: FieldTokens.labelStyle(typography, colors, brightness),
        ),
        SizedBox(height: labelGap),
        SizedBox(
          height: fieldHeight,
          child: TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            onChanged: onChanged,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: FieldTokens.valueStyle(
              typography,
              colors,
              brightness,
              enabled: enabled,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: FieldTokens.hintStyle(
                typography,
                colors,
                brightness,
                enabled: enabled,
              ),
              prefixIcon: GestureDetector(
                onTap: enabled ? onCountryTap : null,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: responsiveDimension(FieldTokens.horizontalPadding),
                    right: AppSpacing.sm,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        countryFlagAsset,
                        package: AppAssets.package,
                        width: iconSize,
                        height: iconSize,
                      ),
                    ],
                  ),
                ),
              ),
              prefixIconConstraints: BoxConstraints(
                minWidth: responsiveDimension(FieldTokens.horizontalPadding) +
                    iconSize +
                    AppSpacing.sm,
                minHeight: fieldHeight,
              ),
              filled: true,
              fillColor: FieldTokens.background(
                colors,
                brightness,
                enabled: enabled,
              ),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: responsiveDimension(FieldTokens.horizontalPadding),
                vertical: responsiveDimension(FieldTokens.verticalPadding),
              ),
              border: _border(colors, brightness, focused: false, errored: _hasError),
              enabledBorder: _border(colors, brightness, focused: false, errored: _hasError),
              focusedBorder: _border(colors, brightness, focused: true, errored: _hasError),
              disabledBorder: _border(
                colors,
                brightness,
                focused: false,
                disabled: true,
              ),
            ),
          ),
        ),
        if (_hasError) ...[
          SizedBox(height: responsiveDimension(FieldTokens.captionGap)),
          Text(
            errorText!,
            style: FieldTokens.errorStyle(typography, colors, brightness),
          ),
        ],
      ],
    );
  }

  OutlineInputBorder _border(
    AppColors colors,
    Brightness brightness, {
    required bool focused,
    bool disabled = false,
    bool errored = false,
  }) {
    final color = disabled
        ? FieldTokens.disabledBorder(colors, brightness)
        : errored
            ? colors.error
            : focused
                ? FieldTokens.focusBorder(colors)
                : FieldTokens.borderDefault(colors, brightness);
    final width = focused
        ? responsiveDimension(FieldTokens.borderWidthEmphasis)
        : responsiveDimension(FieldTokens.borderWidthDefault);

    return FieldTokens.outlineBorder(color, width);
  }
}
