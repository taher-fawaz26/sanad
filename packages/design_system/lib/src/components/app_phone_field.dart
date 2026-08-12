import 'package:app_assets/app_assets.dart';
import 'package:core/core.dart';
import 'package:design_system/src/components/app_field_label.dart';
import 'package:design_system/src/components/app_field_trailing.dart';
import 'package:design_system/src/components/app_verified_badge.dart';
import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/spacing/responsive_spacing.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/colors/field_tokens.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Figma phone field (`1616:12907`) — flag + country code prefix + number.
///
/// The dial code is rendered in the prefix only. Any E.164 / `971…` value
/// passed via [controller] is stripped to national digits so the code is
/// never shown twice.
class AppPhoneField extends StatefulWidget {
  const AppPhoneField({
    required this.label,
    super.key,
    this.controller,
    this.hint,
    this.onChanged,
    this.enabled = true,
    this.isRequired = false,
    this.countryFlagAsset = AppSvgs.flagAe,
    this.countryCode = '+971',
    this.onCountryTap,
    this.errorText,
    this.trailing,
    this.showVerifiedBadge = false,
    this.readOnly = false,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  /// When `true`, appends a red `*` after the label.
  final bool isRequired;
  final String countryFlagAsset;

  /// Dial code shown after the flag (Figma `+971`).
  final String countryCode;

  final VoidCallback? onCountryTap;

  /// When non-null, the field renders with an error border and this
  /// message below it (Figma field error state).
  final String? errorText;

  /// Inline trailing action — e.g. text link Change (`3784:17463`).
  final AppFieldTrailing? trailing;

  /// Shows [AppVerifiedBadge] beside the label — Figma `3784:17466`.
  final bool showVerifiedBadge;

  /// Read-only display for verified phone with trailing Change action.
  final bool readOnly;

  /// Gap between flag and country-code group — Figma `gap-[14px]`.
  static const double _prefixGap = 14;

  @override
  State<AppPhoneField> createState() => _AppPhoneFieldState();
}

class _AppPhoneFieldState extends State<AppPhoneField> {
  TextEditingController? _ownedController;
  TextEditingController get _controller =>
      widget.controller ?? _ownedController!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _ownedController = TextEditingController();
    }
    _stripDialCodeFromController();
  }

  @override
  void didUpdateWidget(AppPhoneField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (widget.controller == null) {
        _ownedController ??= TextEditingController();
      } else {
        _ownedController?.dispose();
        _ownedController = null;
      }
    }
    _stripDialCodeFromController();
  }

  @override
  void dispose() {
    _ownedController?.dispose();
    super.dispose();
  }

  void _stripDialCodeFromController() {
    final national = UaePhoneValidator.toNationalInput(_controller.text);
    if (national == _controller.text) return;
    // Deferred: mutating an externally-owned controller synchronously here
    // (initState/didUpdateWidget) can re-enter a still-in-progress ancestor
    // build if that ancestor listens on the same controller and calls
    // setState from the listener — trips the framework's `!_dirty`
    // assertion. A post-frame callback breaks the re-entrancy; the one-frame
    // delay before the dial code is stripped is imperceptible.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final current = _controller.text;
      final resolved = UaePhoneValidator.toNationalInput(current);
      if (resolved == current) return;
      _controller.value = TextEditingValue(
        text: resolved,
        selection: TextSelection.collapsed(offset: resolved.length),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final brightness = Theme.of(context).brightness;
    final fieldHeight = responsiveDimension(FieldTokens.fieldHeight);
    final labelGap = responsiveDimension(FieldTokens.labelGap);
    final iconSize = AppDimension.iconLg;
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    final dark = colors.palettes.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppFieldLabel(
          label: widget.label,
          isRequired: widget.isRequired && !widget.showVerifiedBadge,
          suffix: widget.showVerifiedBadge ? const AppVerifiedBadge() : null,
        ),
        SizedBox(height: labelGap),
        SizedBox(
          height: fieldHeight,
          child: TextField(
            controller: _controller,
            enabled: widget.enabled,
            readOnly: widget.readOnly,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            onChanged: widget.onChanged,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: FieldTokens.valueStyle(
              typography,
              colors,
              brightness,
              enabled: widget.enabled,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: FieldTokens.hintStyle(
                typography,
                colors,
                brightness,
                enabled: widget.enabled,
              ),
              prefixIcon: GestureDetector(
                onTap: widget.enabled ? widget.onCountryTap : null,
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
                        widget.countryFlagAsset,
                        package: AppAssets.package,
                        width: iconSize,
                        height: iconSize,
                      ),
                      SizedBox(
                        width: responsiveSpacing(AppPhoneField._prefixGap),
                      ),
                      Text(
                        widget.countryCode,
                        style: typography.regularNone.copyWith(
                          fontWeight: FontWeight.w600,
                          color: widget.enabled
                              ? dark.shade900
                              : FieldTokens.valueColor(
                                  colors,
                                  brightness,
                                  enabled: false,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              prefixIconConstraints: BoxConstraints(
                minWidth:
                    responsiveDimension(FieldTokens.horizontalPadding) +
                    iconSize +
                    responsiveSpacing(AppPhoneField._prefixGap) +
                    responsiveDimension(40) +
                    AppSpacing.sm,
                minHeight: fieldHeight,
              ),
              suffixIcon: widget.trailing != null
                  ? Padding(
                      padding: EdgeInsetsDirectional.only(
                        end: responsiveDimension(FieldTokens.trailingPadding),
                      ),
                      child: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: AppFieldTrailingView(
                          trailing: widget.trailing!,
                          enabled: widget.enabled,
                        ),
                      ),
                    )
                  : null,
              suffixIconConstraints: widget.trailing != null
                  ? FieldTokens.trailingSuffixConstraints()
                  : null,
              filled: true,
              fillColor: FieldTokens.background(
                colors,
                brightness,
                enabled: widget.enabled,
              ),
              isDense: true,
              contentPadding: widget.trailing != null
                  ? EdgeInsets.fromLTRB(
                      responsiveDimension(FieldTokens.trailingPadding),
                      responsiveDimension(FieldTokens.trailingPadding),
                      0,
                      responsiveDimension(FieldTokens.trailingPadding),
                    )
                  : EdgeInsets.symmetric(
                      horizontal: responsiveDimension(
                        FieldTokens.horizontalPadding,
                      ),
                      vertical: responsiveDimension(
                        FieldTokens.verticalPadding,
                      ),
                    ),
              border: _border(
                colors,
                brightness,
                focused: false,
                error: hasError,
              ),
              enabledBorder: _border(
                colors,
                brightness,
                focused: false,
                error: hasError,
              ),
              focusedBorder: _border(
                colors,
                brightness,
                focused: true,
                error: hasError,
              ),
              disabledBorder: _border(
                colors,
                brightness,
                focused: false,
                disabled: true,
              ),
            ),
          ),
        ),
        if (hasError) ...[
          SizedBox(height: labelGap),
          Text(
            widget.errorText!,
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
    bool error = false,
  }) {
    final color = disabled
        ? FieldTokens.disabledBorder(colors, brightness)
        : error
        ? FieldTokens.errorBorder(colors, brightness)
        : focused
        ? FieldTokens.focusBorder(colors)
        : FieldTokens.borderDefault(colors, brightness);
    final width = focused
        ? responsiveDimension(FieldTokens.borderWidthEmphasis)
        : responsiveDimension(FieldTokens.borderWidthDefault);

    return FieldTokens.outlineBorder(color, width);
  }
}
