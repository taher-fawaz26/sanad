import 'package:app_animations/app_animations.dart';
import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:otp/src/presentation/config/otp_flow_config.dart';
import 'package:otp/src/presentation/view/otp_parts.dart';

/// The sanad_client OTP screen — Figma `6979:27634` (counting down),
/// `6979:27585` / `7063:25563` (resend available), `7063:25609` (invalid
/// code).
///
/// Structure, top to bottom: leading icon circle → start-aligned title +
/// supporting line → compact code cells → a single resend slot (the
/// countdown caption and the "Didn't receive the code?" row are mutually
/// exclusive here) → action.
///
/// The action is pinned to a bottom bar when the host gives this widget
/// bounded height (`OtpFlowConfig.pinActionToBottom`); otherwise it flows
/// inline, so the layout is safe inside a content-sized sheet too.
///
/// Nothing in this file is read by the provider layout — changing the client
/// spec here cannot move a pixel in the provider app.
class ClientOtpLayout<T> extends StatelessWidget {
  const ClientOtpLayout({
    required this.config,
    required this.controller,
    super.key,
  });

  final OtpFlowConfig<T> config;
  final TextEditingController controller;

  /// Figma `6979:27635` — the body's own inset. Suppressed in a sheet, whose
  /// chrome already applies the design system's sheet padding.
  static const double _horizontalPadding = 24;

  /// Figma `6979:27635` — `pt-[40px]` below the nav bar.
  static const double _topPadding = 40;

  /// Figma `6979:27635` — the uniform `gap-[24px]` between body sections.
  static const double _sectionGap = 24;

  /// Figma `6979:27656` — the bottom bar's `pt-[12px]` / `pb-[8px]`.
  static const double _bottomBarTopPadding = 12;
  static const double _bottomBarBottomPadding = 8;

  /// Figma `6979:27636` — the icon circle.
  static const double _iconCircleSize = 56;

  /// Figma `7063:25609` — the OTP screen's own caption red, distinct from the
  /// shared field-error red (`FieldTokens.errorBorder`) and the OTP cell's
  /// own error border/text red (`colors.palettes.red.shade500`). Not bound to
  /// any design-system or Figma variable, so there is no shared token to
  /// reuse here.
  static const Color _errorTextColor = Color(0xFFD93025);

  /// Figma `7063:1532` — "Resend code in 0:45"'s caption color. Bound to a
  /// legacy `Text Color/text-grey` Figma variable distinct from the current
  /// palette; no design-system token matches it.
  static const Color _countdownColor = Color(0xFF9EA2AE);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final gap = responsiveDimension(_sectionGap);

    final contentChildren = <Widget>[
      OtpDispatchBanner<T>(config: config),
      const _ClientOtpIcon(),
      SizedBox(height: gap),
      OtpHeader<T>(
        config: config,
        defaultTitleKey: 'otp.client.title',
        defaultSubtitleKey: 'otp.client.subtitle',
        titleStyle: typography.title3.copyWith(
          fontSize: 28.rfs,
          fontWeight: FontWeight.w700,
          color: colors.textPrimary,
        ),
        subtitleStyle: typography.regularNormal.copyWith(
          fontSize: 15.rfs,
          height: 1.4,
          color: colors.textMuted,
        ),
        destinationStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: colors.textPrimary,
        ),
        changeStyle: TextStyle(
          color: colors.primary,
          fontWeight: FontWeight.w600,
        ),
        gap: responsiveDimension(AppSpacing.sm),
        alignment: CrossAxisAlignment.start,
        // Figma `6979:27639` ends the sentence after the address.
        destinationSuffix: '.',
      ),
      SizedBox(height: gap),
      OtpCodeField<T>(
        config: config,
        controller: controller,
        metrics: const AppOtpFieldMetrics.standard(),
        invalidCodeKey: 'otp.client.invalid_code',
        errorTextStyle: typography.smallNormal.copyWith(
          fontWeight: FontWeight.w500,
          color: _errorTextColor,
        ),
      ),
      SizedBox(height: gap),
      // Figma draws these two as alternatives, never together: a centered
      // countdown caption while the cooldown runs, then the start-aligned
      // "Didn't receive the code? Resend Code" row once it is spent.
      OtpCountdown<T>(
        padMinutes: false,
        labelKey: 'otp.client.resend_countdown',
        style: typography.smallNormal.copyWith(color: _countdownColor),
        whenIdle: OtpResendRow<T>(
          promptKey: 'otp.client.not_received',
          actionKey: 'otp.client.resend',
          promptStyle: typography.regularNormal.copyWith(
            fontSize: 14.rfs,
            color: colors.textMuted,
          ),
          actionStyle: TextStyle(
            color: colors.primary,
            fontWeight: FontWeight.w600,
          ),
          disabledActionStyle: TextStyle(
            color: colors.textMuted,
            fontWeight: FontWeight.w600,
          ),
          centered: false,
        ),
      ),
      // Shown only once the server reports a count; collapses to nothing
      // otherwise, leaving the frame exactly as Figma draws it.
      OtpResendsLeft<T>(
        padding: EdgeInsets.only(top: responsiveDimension(AppSpacing.xs)),
        style: typography.smallNormal.copyWith(color: colors.textMuted),
        centered: false,
      ),
      if (!config.pinActionToBottom) ...[
        SizedBox(height: responsiveDimension(AppSpacing.lg)),
        _verifyButton,
      ],
    ];

    // A sheet's own chrome already insets its child; a page has nothing but
    // this padding.
    final horizontal = config.presentAsSheet
        ? 0.0
        : responsiveDimension(_horizontalPadding);

    final scrollableContent = SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        horizontal,
        responsiveDimension(_topPadding),
        horizontal,
        responsiveDimension(AppSpacing.lg),
      ),
      // Opt-in one-shot staggered entrance for the client OAuth OTP page
      // (`OtpFlowConfig.animateContent`). `AppStaggeredColumn` plays once on
      // mount and does not replay on the bloc's subsequent rebuilds, and is
      // reduced-motion aware.
      child: config.animateContent
          ? AppStaggeredColumn(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: contentChildren,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: contentChildren,
            ),
    );

    if (!config.pinActionToBottom) return scrollableContent;

    // Figma `6979:27656` — the action sits in its own bottom bar with the
    // scrollable content filling everything above it. Requires bounded
    // height from the host (see `OtpFlowConfig.pinActionToBottom`).
    return Column(
      children: [
        Expanded(child: scrollableContent),
        Padding(
          padding: EdgeInsets.fromLTRB(
            horizontal,
            responsiveDimension(_bottomBarTopPadding),
            horizontal,
            responsiveDimension(_bottomBarBottomPadding),
          ),
          child: _verifyButton,
        ),
      ],
    );
  }

  Widget get _verifyButton =>
      OtpVerifyButton<T>(config: config, defaultLabelKey: 'otp.verify');
}

/// Figma `6979:27636` / `7063:25587` — the same `sky/100` circle + 24dp glyph
/// pattern as the OAuth Email/Phone entry screens' own icon circles.
class _ClientOtpIcon extends StatelessWidget {
  const _ClientOtpIcon();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    // The parent Column uses crossAxisAlignment.stretch (needed by the
    // header/field/resend children below), which hands every direct child
    // TIGHT width constraints — a plain Container's own `width: 56` request
    // loses to that and gets stretched full-width. Align opts this one child
    // back out: it forwards loose constraints, so the Container's requested
    // size wins, exactly like the un-stretched Column (crossAxisAlignment:
    // start) OAuthEmailPage/OAuthPhonePage use for the same icon circle.
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        width: responsiveDimension(ClientOtpLayout._iconCircleSize),
        height: responsiveDimension(ClientOtpLayout._iconCircleSize),
        decoration: BoxDecoration(
          color: colors.palettes.sky.shade100,
          borderRadius: AppRadius.circularXl,
        ),
        child: Center(
          child: AppSvgPicture.asset(
            AppSvgs.otpPasswordCursor,
            width: responsiveDimension(AppDimension.iconMenu),
            height: responsiveDimension(AppDimension.iconMenu),
          ),
        ),
      ),
    );
  }
}
