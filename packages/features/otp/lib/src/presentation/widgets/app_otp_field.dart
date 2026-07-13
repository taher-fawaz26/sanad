import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';

/// Default OTP / PIN length used across the app.
const int kDefaultOtpLength = 5;

/// Reusable OTP pin field built on [Pinput], styled with design-system tokens.
///
/// Safe to use on full screens, bottom sheets, dialogs, or any other surface.
class AppOtpField extends StatelessWidget {
  const AppOtpField({
    super.key,
    this.controller,
    this.focusNode,
    this.length = kDefaultOtpLength,
    this.enabled = true,
    this.autofocus = false,
    this.forceErrorState = false,
    this.errorText,
    this.validator,
    this.onChanged,
    this.onCompleted,
    this.onSubmitted,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;

  /// Number of pin cells. Defaults to [kDefaultOtpLength] (5).
  final int length;
  final bool enabled;
  final bool autofocus;
  final bool forceErrorState;
  final String? errorText;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final brightness = Theme.of(context).brightness;
    final cellSize = AppDimension.otpCellSize;
    final radius = FieldTokens.borderRadiusAll();
    final defaultWidth = responsiveDimension(FieldTokens.borderWidthDefault);
    final emphasisWidth = responsiveDimension(FieldTokens.borderWidthEmphasis);

    final textStyle = FieldTokens.valueStyle(
      typography,
      colors,
      brightness,
      enabled: enabled,
    );

    PinTheme themeFor({
      required Color borderColor,
      required double borderWidth,
      Color? fillColor,
    }) {
      return PinTheme(
        width: cellSize,
        height: cellSize,
        textStyle: textStyle,
        decoration: BoxDecoration(
          color: fillColor ??
              FieldTokens.background(colors, brightness, enabled: enabled),
          borderRadius: radius,
          border: Border.all(color: borderColor, width: borderWidth),
        ),
      );
    }

    final hasError =
        forceErrorState || (errorText != null && errorText!.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Directionality(
          // OTP digits stay LTR in Arabic layouts.
          textDirection: TextDirection.ltr,
          child: Pinput(
            controller: controller,
            focusNode: focusNode,
            length: length,
            enabled: enabled,
            autofocus: autofocus,
            forceErrorState: hasError,
            defaultPinTheme: themeFor(
              borderColor: FieldTokens.borderDefault(colors, brightness),
              borderWidth: defaultWidth,
            ),
            focusedPinTheme: themeFor(
              borderColor: FieldTokens.focusBorder(colors),
              borderWidth: emphasisWidth,
            ),
            errorPinTheme: themeFor(
              borderColor: FieldTokens.errorBorder(colors, brightness),
              borderWidth: emphasisWidth,
            ),
            disabledPinTheme: themeFor(
              borderColor: FieldTokens.disabledBorder(colors, brightness),
              borderWidth: defaultWidth,
              fillColor:
                  FieldTokens.background(colors, brightness, enabled: false),
            ),
            submittedPinTheme: themeFor(
              borderColor: FieldTokens.borderDefault(colors, brightness),
              borderWidth: defaultWidth,
            ),
            separatorBuilder: (_) => SizedBox(width: AppSpacing.sm),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            hapticFeedbackType: HapticFeedbackType.lightImpact,
            closeKeyboardWhenCompleted: true,
            validator: validator,
            onChanged: onChanged,
            onCompleted: onCompleted,
            onSubmitted: onSubmitted,
          ),
        ),
        if (hasError && errorText != null && errorText!.isNotEmpty) ...[
          SizedBox(height: AppSpacing.sm),
          Text(
            errorText!,
            textAlign: TextAlign.center,
            style: FieldTokens.errorStyle(typography, colors, brightness),
          ),
        ],
      ],
    );
  }
}
