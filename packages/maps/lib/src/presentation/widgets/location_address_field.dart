import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Read-only address card used by map pickers.
class LocationAddressField extends StatelessWidget {
  const LocationAddressField({
    required this.label,
    required this.hint,
    this.value,
    super.key,
  });

  final String label;
  final String? value;
  final String hint;

  bool get _hasValue => value != null && value!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final brightness = Theme.of(context).brightness;
    final fieldHeight = responsiveDimension(80);
    final labelGap = responsiveDimension(FieldTokens.labelGap);
    final iconSize = AppDimension.iconLg;

    final displayStyle = _hasValue
        ? FieldTokens.valueStyle(
            typography,
            colors,
            brightness,
            enabled: true,
          )
        : FieldTokens.hintStyle(
            typography,
            colors,
            brightness,
            enabled: true,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: FieldTokens.labelStyle(typography, colors, brightness),
        ),
        SizedBox(height: labelGap),
        Material(
          color: FieldTokens.background(colors, brightness, enabled: true),
          shape: RoundedRectangleBorder(
            borderRadius: FieldTokens.borderRadiusAll(),
            side: BorderSide(
              color: FieldTokens.borderDefault(colors, brightness),
              width: responsiveDimension(FieldTokens.borderWidthDefault),
            ),
          ),
          child: SizedBox(
            height: fieldHeight,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: responsiveDimension(FieldTokens.horizontalPadding),
                vertical: responsiveDimension(FieldTokens.verticalPadding),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSvgPicture.asset(
                    AppSvgs.map,
                    width: iconSize,
                    height: iconSize,
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      _hasValue ? value! : hint,
                      style: displayStyle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
