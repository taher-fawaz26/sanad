import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/spacing/responsive_spacing.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/colors/field_tokens.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Figma `Controls / Text Fields with Label or Caption` (`6:257`).
///
/// Wraps [TextFormField] with optional label, caption, and error message
/// slots matching the design-system field component.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.caption,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.inputFormatters,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hint;
  final String? caption;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final brightness = Theme.of(context).brightness;
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: FieldTokens.labelStyle(typography, colors),
          ),
          SizedBox(height: AppSpacing.md),
        ],
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          readOnly: readOnly,
          autofocus: autofocus,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          validator: validator,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          textCapitalization: textCapitalization,
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
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            prefixIconConstraints: FieldTokens.prefixIconConstraints(),
            suffixIconConstraints: FieldTokens.suffixIconConstraints(),
            filled: true,
            fillColor: FieldTokens.background(
              colors,
              brightness,
              enabled: enabled,
            ),
            isDense: true,
            contentPadding: FieldTokens.contentPadding(
              hasPrefixIcon: prefixIcon != null,
            ),
            border: _border(
              colors,
              brightness,
              enabled: enabled,
              hasError: hasError,
              focused: false,
            ),
            enabledBorder: _border(
              colors,
              brightness,
              enabled: enabled,
              hasError: hasError,
              focused: false,
            ),
            focusedBorder: _border(
              colors,
              brightness,
              enabled: enabled,
              hasError: hasError,
              focused: true,
            ),
            disabledBorder: _border(
              colors,
              brightness,
              enabled: false,
              hasError: false,
              focused: false,
            ),
            errorBorder: _border(
              colors,
              brightness,
              enabled: enabled,
              hasError: true,
              focused: false,
            ),
            focusedErrorBorder: _border(
              colors,
              brightness,
              enabled: enabled,
              hasError: true,
              focused: true,
            ),
            errorText: hasError ? errorText : null,
            helperText: hasError ? null : caption,
            errorStyle: FieldTokens.errorStyle(typography, colors),
            helperStyle: FieldTokens.captionStyle(
              typography,
              colors,
              brightness,
            ),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _border(
    AppColors colors,
    Brightness brightness, {
    required bool enabled,
    required bool hasError,
    required bool focused,
  }) {
    final color = !enabled
        ? FieldTokens.disabledBorder(colors, brightness)
        : hasError
            ? FieldTokens.errorBorder(colors)
            : focused
                ? FieldTokens.focusBorder(colors)
                : FieldTokens.borderDefault(colors, brightness);

    final hairline = AppDimension.borderHairline;
    final width = focused || hasError ? hairline * 2 : hairline;

    return OutlineInputBorder(
      borderRadius: FieldTokens.borderRadiusAll(),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
