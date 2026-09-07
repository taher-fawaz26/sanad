import 'package:app_animations/app_animations.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:otp/src/presentation/config/otp_flow_config.dart';
import 'package:otp/src/presentation/view/otp_parts.dart';

/// The sanad_provider OTP screen — Figma `2142:14121` (page, inside
/// `AuthScreenShell`), `3809:18083` (bottom sheet) and `3809:18133` (bottom
/// sheet, invalid code).
///
/// Structure, top to bottom: centered title + supporting line → large code
/// cells → the action → a teal countdown → a centered resend row. Note the
/// two deliberate departures from the client spec beyond styling:
///
/// * there is **no** leading icon, and everything is center-aligned;
/// * the action sits inline *above* the countdown, and the countdown and the
///   resend row are shown **together** (the resend link simply greys out
///   while the cooldown runs) rather than replacing one another.
///
/// Page and sheet share this layout and differ only where their frames do —
/// the header's internal gap and the weight/size of the supporting line.
///
/// Nothing in this file is read by the client layout — changing the provider
/// spec here cannot move a pixel in the client app.
class ProviderOtpLayout<T> extends StatelessWidget {
  const ProviderOtpLayout({
    required this.config,
    required this.controller,
    super.key,
  });

  final OtpFlowConfig<T> config;
  final TextEditingController controller;

  /// Figma `2142:14136` — `px-[20px]`. Suppressed in a sheet, whose chrome
  /// already applies the design system's sheet padding.
  static const double _horizontalPadding = 20;

  /// Figma `2142:14136` — `py-[64px]`, of which `AuthScreenShell` already
  /// contributes 40 around its card content.
  static const double _pageVerticalPadding = 24;

  /// Figma `3809:18085` — the sheet's `pt-[9px]`/`pb-[16px]` around the
  /// content block, below the drag handle the sheet chrome draws.
  static const double _sheetVerticalPadding = 16;

  /// Figma `3809:18088` / `2142:14136` — the `gap-[48px]` between sections.
  static const double _sectionGap = 48;

  /// Figma `3809:18090` — the title's `#111`. A legacy Figma literal; no
  /// design-system token carries it (`DarkPalette.shade900` is `#212324`).
  static const Color _titleColor = Color(0xFF111111);

  /// Figma `3809:18091` — the supporting line's `#4b4b4b`, between
  /// `DarkPalette.shade700` and `shade800`.
  static const Color _subtitleColor = Color(0xFF4B4B4B);

  /// Figma style `Gray/500` (`#667085`) on `3809:18103`. From the same legacy
  /// collection as the client screen's `#9EA2AE` caption grey — unrelated to
  /// the current `DarkPalette`.
  static const Color _resendPromptColor = Color(0xFF667085);

  /// Figma `3809:18090` — 32/40.
  static const double _titleFontSize = 32;
  static const double _titleLineHeight = 40 / _titleFontSize;

  /// Figma `3809:18091` (sheet) / `2142:14139` (page) — both 24px leading.
  static const double _sheetSubtitleFontSize = 16;
  static const double _pageSubtitleFontSize = 14;

  /// Figma `3809:18099` — the countdown's 16/25.
  static const double _countdownFontSize = 16;
  static const double _countdownLineHeight = 25 / _countdownFontSize;

  /// Figma `3809:18103` — the resend row's 16/20.
  static const double _resendFontSize = 16;
  static const double _resendLineHeight = 20 / _resendFontSize;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final gap = responsiveDimension(_sectionGap);
    final isSheet = config.presentAsSheet;

    final subtitleFontSize = isSheet
        ? _sheetSubtitleFontSize
        : _pageSubtitleFontSize;

    final children = <Widget>[
      OtpDispatchBanner<T>(config: config),
      OtpHeader<T>(
        config: config,
        defaultTitleKey: 'otp.title',
        defaultSubtitleKey: 'otp.subtitle',
        titleStyle: typography.title3.copyWith(
          fontSize: _titleFontSize.rfs,
          height: _titleLineHeight,
          fontWeight: FontWeight.w600,
          color: _titleColor,
        ),
        subtitleStyle: typography.regularNormal.copyWith(
          fontSize: subtitleFontSize.rfs,
          height: 24 / subtitleFontSize,
          fontWeight: isSheet ? FontWeight.w500 : FontWeight.w400,
          color: _subtitleColor,
        ),
        // Figma renders the address in the same weight as the sentence; only
        // the "Change" affordance is emphasised.
        destinationStyle: const TextStyle(color: _subtitleColor),
        changeStyle: TextStyle(
          color: colors.primary,
          fontWeight: isSheet ? FontWeight.w700 : FontWeight.w500,
          decoration: TextDecoration.underline,
          decorationColor: colors.primary,
        ),
        gap: responsiveDimension(isSheet ? AppSpacing.md : AppSpacing.sm),
        alignment: CrossAxisAlignment.center,
      ),
      SizedBox(height: gap),
      OtpCodeField<T>(
        config: config,
        controller: controller,
        metrics: const AppOtpFieldMetrics.large(),
        invalidCodeKey: 'otp.invalid_code',
        // Keeps `AppOtpField`'s shared field-error caption style — the
        // provider frames give the error state no caption of its own beyond
        // the red cells.
        errorTextStyle: null,
      ),
      SizedBox(height: gap),
      OtpVerifyButton<T>(config: config, defaultLabelKey: 'otp.verify'),
      // Unlike the client screen these two coexist: the countdown collapses
      // (taking its own leading gutter with it) when it reaches zero, and the
      // resend row below it becomes tappable.
      OtpCountdown<T>(
        padMinutes: true,
        padding: EdgeInsets.only(top: gap),
        style: typography.regularNormal.copyWith(
          fontSize: _countdownFontSize.rfs,
          height: _countdownLineHeight,
          fontWeight: FontWeight.w500,
          color: colors.primary,
        ),
      ),
      SizedBox(height: gap),
      OtpResendRow<T>(
        promptKey: 'otp.not_received',
        actionKey: 'otp.send_again',
        promptStyle: typography.regularNormal.copyWith(
          fontSize: _resendFontSize.rfs,
          height: _resendLineHeight,
          fontWeight: FontWeight.w500,
          color: _resendPromptColor,
        ),
        actionStyle: TextStyle(
          color: colors.primary,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
          decorationColor: colors.primary,
        ),
        disabledActionStyle: TextStyle(
          color: colors.textDisabled,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
          decorationColor: colors.textDisabled,
        ),
        centered: true,
      ),
      // Shown only once the server reports a count; collapses to nothing
      // otherwise, leaving the frame exactly as Figma draws it.
      OtpResendsLeft<T>(
        padding: EdgeInsets.only(top: responsiveDimension(AppSpacing.sm)),
        style: typography.smallNormal.copyWith(
          fontWeight: FontWeight.w500,
          color: _resendPromptColor,
        ),
        centered: true,
      ),
    ];

    // A sheet's own chrome already insets its child; a page has nothing but
    // this padding (plus whatever card padding its host shell contributes).
    final horizontal = isSheet ? 0.0 : responsiveDimension(_horizontalPadding);
    final vertical = responsiveDimension(
      isSheet ? _sheetVerticalPadding : _pageVerticalPadding,
    );

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: horizontal,
        vertical: vertical,
      ),
      child: config.animateContent
          ? AppStaggeredColumn(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: children,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: children,
            ),
    );
  }
}
