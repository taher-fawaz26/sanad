import 'package:design_system/src/components/app_field_label.dart';
import 'package:design_system/src/components/app_field_trailing.dart';
import 'package:design_system/src/components/app_verified_badge.dart';
import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/colors/field_tokens.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Figma `Controls / Text Fields with Label or Caption` (`6:257`).
///
/// Supports all 15 Figma variants across states:
/// Default, Focused, Filled, Error, and Disabled — with or without
/// label and caption.
class AppTextField extends StatefulWidget {
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
    this.trailing,
    this.showVerifiedBadge = false,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.isRequired = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.inputFormatters,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
    this.autovalidateMode,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hint;
  final String? caption;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  /// Inline trailing action — outline pill (`3784:17518`) or text link
  /// (`3784:17463`). Takes precedence over [suffixIcon] when set.
  final AppFieldTrailing? trailing;

  /// Shows [AppVerifiedBadge] beside the label — Figma `3784:17466`.
  final bool showVerifiedBadge;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;

  /// When `true` and [label] is set, appends a red `*` after the label.
  final bool isRequired;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final TextCapitalization textCapitalization;
  final AutovalidateMode? autovalidateMode;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  // Cache computed values to avoid recalculating on every build
  late final double _fieldHeight;
  late final double _labelGap;
  late final double _captionGap;

  @override
  void initState() {
    super.initState();
    // Pre-calculate responsive dimensions once
    _fieldHeight = responsiveDimension(FieldTokens.fieldHeight);
    _labelGap = responsiveDimension(FieldTokens.labelGap);
    _captionGap = responsiveDimension(FieldTokens.captionGap);
  }

  @override
  Widget build(BuildContext context) {
    // Single theme lookups cached in local variables
    final colors = context.appColors;
    final typography = context.appTypography;
    final brightness = Theme.of(context).brightness;

    return FormField<String>(
      validator: (value) {
        final resolved = value ?? widget.controller?.text ?? '';
        return widget.validator?.call(resolved);
      },
      initialValue: widget.controller?.text ?? '',
      autovalidateMode: widget.autovalidateMode,
      enabled: widget.enabled,
      builder: (field) {
        final resolvedError = _resolveError(field);
        final hasError = resolvedError != null && resolvedError.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.label != null) ...[
              AppFieldLabel(
                label: widget.label!,
                isRequired: widget.isRequired && !widget.showVerifiedBadge,
                suffix: widget.showVerifiedBadge
                    ? const AppVerifiedBadge()
                    : null,
              ),
              SizedBox(height: _labelGap),
            ],
            _wrapFieldHeight(
              Material(
                type: MaterialType.transparency,
                child: TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  enabled: widget.enabled,
                  readOnly: widget.readOnly,
                  autofocus: widget.autofocus,
                  obscureText: widget.obscureText,
                  keyboardType:
                      widget.keyboardType ??
                      (widget.maxLines > 1 ? TextInputType.multiline : null),
                  textInputAction: widget.textInputAction,
                  onChanged: (value) {
                    field.didChange(value);
                    widget.onChanged?.call(value);
                  },
                  onSubmitted: widget.onSubmitted,
                  inputFormatters: widget.inputFormatters,
                  minLines: widget.maxLines > 1 ? widget.maxLines : null,
                  maxLines: widget.maxLines,
                  textCapitalization: widget.textCapitalization,
                  style: FieldTokens.valueStyle(
                    typography,
                    colors,
                    brightness,
                    enabled: widget.enabled,
                  ),
                  decoration: _buildDecoration(
                    colors: colors,
                    typography: typography,
                    brightness: brightness,
                    hasError: hasError,
                  ),
                ),
              ),
            ),
            if (hasError) ...[
              SizedBox(height: _captionGap),
              Text(
                resolvedError,
                style: FieldTokens.errorStyle(typography, colors, brightness),
              ),
            ] else if (widget.caption != null &&
                widget.caption!.isNotEmpty) ...[
              SizedBox(height: _captionGap),
              Text(
                widget.caption!,
                style: FieldTokens.captionStyle(typography, colors, brightness),
              ),
            ],
          ],
        );
      },
    );
  }

  String? _resolveError(FormFieldState<String> field) {
    if (widget.errorText != null && widget.errorText!.isNotEmpty) {
      return widget.errorText;
    }
    return field.errorText;
  }

  /// Single-line fields keep the Figma 48px height. Multiline fields size
  /// from padding + line-height × maxLines so maxLines is visible.
  Widget _wrapFieldHeight(Widget child) {
    if (widget.maxLines <= 1) {
      return SizedBox(height: _fieldHeight, child: child);
    }
    return SizedBox(height: _multilineFieldHeight, child: child);
  }

  /// Matches Figma single-line math: vertical padding × 2 + 16 line height,
  /// extended by `(maxLines - 1)` additional lines.
  double get _multilineFieldHeight {
    final lineHeight = responsiveDimension(16);
    return _fieldHeight + lineHeight * (widget.maxLines - 1);
  }

  InputDecoration _buildDecoration({
    required AppColors colors,
    required AppTypography typography,
    required Brightness brightness,
    required bool hasError,
  }) {
    final isMultiline = widget.maxLines > 1;

    return InputDecoration(
      hintText: widget.hint,
      hintStyle: FieldTokens.hintStyle(
        typography,
        colors,
        brightness,
        enabled: widget.enabled,
      ),
      prefixIcon: widget.prefixIcon,
      suffixIcon: _buildSuffixIcon(enabled: widget.enabled),
      prefixIconConstraints: FieldTokens.prefixIconConstraints(),
      suffixIconConstraints: widget.trailing != null
          ? (isMultiline
                ? BoxConstraints(minHeight: _multilineFieldHeight)
                : FieldTokens.trailingSuffixConstraints())
          : FieldTokens.suffixIconConstraints(),
      // Override theme maxHeight: 48 so multiline fields can grow.
      constraints: isMultiline
          ? BoxConstraints(
              minHeight: _multilineFieldHeight,
              maxHeight: _multilineFieldHeight,
            )
          : null,
      filled: true,
      fillColor: FieldTokens.background(
        colors,
        brightness,
        enabled: widget.enabled,
      ),
      isDense: true,
      contentPadding: FieldTokens.contentPadding(
        hasPrefixIcon: widget.prefixIcon != null,
        hasTrailing: widget.trailing != null || widget.suffixIcon != null,
      ),
      border: _buildBorder(
        colors,
        brightness,
        hasError: hasError,
        focused: false,
      ),
      enabledBorder: _buildBorder(
        colors,
        brightness,
        hasError: hasError,
        focused: false,
      ),
      focusedBorder: _buildBorder(
        colors,
        brightness,
        hasError: hasError,
        focused: true,
      ),
      disabledBorder: _buildBorder(
        colors,
        brightness,
        hasError: false,
        focused: false,
        disabled: true,
      ),
      errorBorder: _buildBorder(
        colors,
        brightness,
        hasError: true,
        focused: false,
      ),
      focusedErrorBorder: _buildBorder(
        colors,
        brightness,
        hasError: true,
        focused: true,
      ),
    );
  }

  OutlineInputBorder _buildBorder(
    AppColors colors,
    Brightness brightness, {
    required bool hasError,
    required bool focused,
    bool disabled = false,
  }) {
    final color = disabled
        ? FieldTokens.disabledBorder(colors, brightness)
        : hasError
        ? FieldTokens.errorBorder(colors, brightness)
        : focused
        ? FieldTokens.focusBorder(colors)
        : FieldTokens.borderDefault(colors, brightness);

    final width = focused || hasError
        ? responsiveDimension(FieldTokens.borderWidthEmphasis)
        : responsiveDimension(FieldTokens.borderWidthDefault);

    return FieldTokens.outlineBorder(color, width);
  }

  Widget? _buildSuffixIcon({required bool enabled}) {
    if (widget.trailing != null) {
      return Padding(
        padding: EdgeInsetsDirectional.only(
          end: responsiveDimension(FieldTokens.trailingPadding),
        ),
        child: Align(
          // Shrink-wrap to the trailing content's own width. Without this,
          // Align (no widthFactor) tries to be "as big as possible" — with
          // suffixIconConstraints leaving maxWidth unbounded, that starves
          // the editable text region of essentially all its width at
          // realistic (narrow) field widths, rendering the value invisible
          // even though it's present and correct in the widget tree.
          widthFactor: 1,
          alignment: widget.maxLines > 1
              ? AlignmentDirectional.topEnd
              : AlignmentDirectional.centerEnd,
          child: AppFieldTrailingView(
            trailing: widget.trailing!,
            enabled: enabled,
          ),
        ),
      );
    }
    return widget.suffixIcon;
  }
}
