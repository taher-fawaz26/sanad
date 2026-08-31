import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/localization.dart';
import 'package:otp/src/presentation/bloc/otp/otp_bloc.dart';
import 'package:otp/src/presentation/config/otp_flow_config.dart';

/// The canonical OTP screen — the only one in the app.
///
/// Layout, typography and spacing follow the approved auth OTP design; the
/// sheet and page presentations differ solely in the container that hosts
/// this widget, never in its contents.
///
/// ### Two error slots, never merged
///
/// A *code* error (wrong, expired) belongs under the field — the user can fix
/// it by retyping. A *dispatch* error (address taken, purpose forbidden,
/// server down) belongs in a banner above the title — retyping cannot help.
/// A cooldown is neither: it is the countdown.
class OtpView<T> extends StatefulWidget {
  const OtpView({required this.config, super.key});

  final OtpFlowConfig<T> config;

  @override
  State<OtpView<T>> createState() => _OtpViewState<T>();
}

class _OtpViewState<T> extends State<OtpView<T>> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;

    final scrollableContent = SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _OtpDispatchBanner<T>(config: config),
          const _OtpIcon(),
          SizedBox(height: responsiveDimension(AppSpacing.xxl)),
          _OtpHeader<T>(config: config),
          SizedBox(height: responsiveDimension(AppSpacing.xxl)),
          _OtpField<T>(config: config, controller: _controller),
          SizedBox(height: responsiveDimension(AppSpacing.xxl)),
          _OtpResendSection<T>(),
          // _OtpAttemptsHint<T>(),
          if (!config.pinActionToBottom) ...[
            SizedBox(height: responsiveDimension(AppSpacing.xl)),
            _OtpVerifyButton<T>(config: config),
          ],
        ],
      ),
    );

    if (!config.pinActionToBottom) return scrollableContent;

    // The Figma "Email OTP" flow pins the button to the bottom of the screen
    // with the scrollable content filling the space above it, rather than
    // flowing inline after the resend row — see
    // `OtpFlowConfig.pinActionToBottom`.
    return Column(
      children: [
        Expanded(child: scrollableContent),
        Padding(
          padding: EdgeInsets.fromLTRB(
            responsiveDimension(AppSpacing.xl),
            0,
            responsiveDimension(AppSpacing.xl),
            responsiveDimension(AppSpacing.lg),
          ),
          child: _OtpVerifyButton<T>(config: config),
        ),
      ],
    );
  }
}

// ── Icon ─────────────────────────────────────────────────────────────────────

/// Figma `7063:25587` — same `sky/100` circle + 24dp glyph pattern as the
/// OAuth Email/Phone entry screens' own icon circles.
class _OtpIcon extends StatelessWidget {
  const _OtpIcon();

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
        width: responsiveDimension(56),
        height: responsiveDimension(56),
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

// ── Header ───────────────────────────────────────────────────────────────────

class _OtpHeader<T> extends StatelessWidget {
  const _OtpHeader({required this.config});

  final OtpFlowConfig<T> config;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return BlocBuilder<OtpBloc<T>, OtpState<T>>(
      buildWhen: (p, c) => p.displayDestination != c.displayDestination,
      builder: (context, state) {
        final subtitle =
            config.subtitleBuilder?.call(context, config) ??
            'otp.subtitle'.tr();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              config.titleBuilder?.call(context, config) ?? 'otp.title'.tr(),
              style: typography.title3.copyWith(
                fontSize: 28.rfs,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            SizedBox(height: responsiveDimension(AppSpacing.sm)),
            Text.rich(
              TextSpan(
                style: typography.regularNormal.copyWith(
                  fontSize: 15.rfs,
                  height: 1.4,
                  color: colors.textMuted,
                ),
                children: [
                  TextSpan(text: '$subtitle '),
                  TextSpan(
                    // The destination (phone/email) is inherently LTR. Wrapped
                    // in an LTR isolate so a leading `+` or digits render at
                    // the visual start of the value, not the end, under an RTL
                    // (Arabic) paragraph. See SAN-770.
                    text: state.displayDestination.ltrIsolated,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  const TextSpan(text: '.'),
                  if (config.onChangeDestination != null) ...[
                    const TextSpan(text: ' '),
                    TextSpan(
                      text: 'common.change'.tr(),
                      style: TextStyle(
                        color: colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => _changeDestination(context),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _changeDestination(BuildContext context) async {
    final bloc = context.read<OtpBloc<T>>();
    final next = await config.onChangeDestination!(context);
    if (next != null) bloc.add(OtpDestinationChanged(next));
  }
}

// ── Dispatch banner ──────────────────────────────────────────────────────────

/// Delivery/session errors. Occupies no space when there is nothing to say.
class _OtpDispatchBanner<T> extends StatelessWidget {
  const _OtpDispatchBanner({required this.config});

  final OtpFlowConfig<T> config;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return BlocBuilder<OtpBloc<T>, OtpState<T>>(
      buildWhen: (p, c) => p.phase != c.phase,
      builder: (context, state) {
        final phase = state.phase;
        final failure = switch (phase) {
          OtpDispatchFailed(:final failure) => failure,
          OtpConflict(:final failure) => failure,
          _ => null,
        };
        if (failure == null) return const SizedBox.shrink();

        final message =
            config.dispatchErrorResolver?.call(failure) ??
            failure.localizedMessage();

        return Padding(
          padding: EdgeInsetsDirectional.only(
            bottom: responsiveDimension(AppSpacing.lg),
          ),
          child: Container(
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.errorContainer,
              borderRadius: BorderRadius.circular(responsiveDimension(12)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: colors.error,
                  size: responsiveDimension(20),
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    message,
                    style: typography.regularNormal.copyWith(
                      color: colors.error,
                    ),
                  ),
                ),
                if (phase is OtpDispatchFailed) ...[
                  SizedBox(width: AppSpacing.sm),
                  GestureDetector(
                    onTap: () => context.read<OtpBloc<T>>().add(
                      const OtpDispatchRetried(),
                    ),
                    child: Text(
                      'otp.retry'.tr(),
                      style: typography.regularNormal.copyWith(
                        color: colors.error,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Field ────────────────────────────────────────────────────────────────────

class _OtpField<T> extends StatelessWidget {
  const _OtpField({required this.config, required this.controller});

  final OtpFlowConfig<T> config;
  final TextEditingController controller;

  /// Figma `7063:25609` — the OTP screen's own caption red, distinct from the
  /// shared field-error red (`FieldTokens.errorBorder`) and the OTP cell's
  /// own error border/text red (`colors.palettes.red.shade500`). Not bound to
  /// any design-system or Figma variable, so there is no shared token to
  /// reuse here.
  static const _errorTextColor = Color(0xFFD93025);

  @override
  Widget build(BuildContext context) {
    final typography = context.appTypography;

    return BlocBuilder<OtpBloc<T>, OtpState<T>>(
      buildWhen: (p, c) => p.phase != c.phase,
      builder: (context, state) {
        final bloc = context.read<OtpBloc<T>>();
        final errorText = switch (state.phase) {
          OtpInvalidCode() => 'otp.invalid_code'.tr(),
          OtpExpiredPhase() => 'otp.expired_code'.tr(),
          _ => null,
        };
        final busy = state.phase is OtpVerifying || state.phase is OtpSending;

        return Center(
          child: AppOtpField(
            controller: controller,
            length: config.length,
            autofocus: config.autofocus,
            enabled: !busy,
            errorText: errorText,
            errorTextStyle: typography.smallNormal.copyWith(
              fontWeight: FontWeight.w500,
              color: _errorTextColor,
            ),
            onChanged: (value) => bloc.add(OtpCodeChanged(value)),
            onCompleted: config.autoSubmit
                ? (value) => bloc.add(OtpSubmitted(value))
                : null,
            onSubmitted: (value) => bloc.add(OtpSubmitted(value)),
          ),
        );
      },
    );
  }
}

class _OtpVerifyButton<T> extends StatelessWidget {
  const _OtpVerifyButton({required this.config});

  final OtpFlowConfig<T> config;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OtpBloc<T>, OtpState<T>>(
      buildWhen: (p, c) => p.phase != c.phase || p.code.length != c.code.length,
      builder: (context, state) {
        final verifying = state.phase is OtpVerifying;
        final ready =
            state.code.length == config.length &&
            state.phase is! OtpSending &&
            state.phase is! OtpVerifiedPhase;

        return AppButton(
          label: config.verifyLabel ?? 'otp.verify'.tr(),
          isLoading: verifying,
          onPressed: ready && !verifying
              ? () => context.read<OtpBloc<T>>().add(const OtpSubmitted())
              : null,
        );
      },
    );
  }
}

// ── Countdown / resend ───────────────────────────────────────────────────────

String _formatSeconds(int seconds) {
  final m = (seconds ~/ 60).toString().padLeft(2, '0');
  final s = (seconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

/// Figma `6979:27634` (counting down) / `6979:27585` & `7063:25563` (can
/// resend) — these two states are mutually exclusive in the design (a single
/// centered countdown caption, or the "Didn't receive it? Resend" row —
/// never both at once), unlike the two independently-visible widgets this
/// replaced.
class _OtpResendSection<T> extends StatelessWidget {
  const _OtpResendSection();

  /// Figma `7063:1532` — "Resend code in 0:45"'s caption color. Bound to a
  /// legacy `Text Color/text-grey` Figma variable distinct from the current
  /// palette; no design-system token matches it.
  static const _countdownColor = Color(0xFF9EA2AE);

  @override
  Widget build(BuildContext context) {
    final typography = context.appTypography;

    return BlocSelector<OtpBloc<T>, OtpState<T>, int>(
      selector: (state) => state.secondsRemaining,
      builder: (context, seconds) {
        if (seconds <= 0) return _OtpResendRow<T>();
        return Center(
          child: Text(
            'otp.resend_countdown'.tr(
              namedArgs: {'time': _formatSeconds(seconds)},
            ),
            style: typography.smallNormal.copyWith(color: _countdownColor),
          ),
        );
      },
    );
  }
}

class _OtpResendRow<T> extends StatelessWidget {
  const _OtpResendRow();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return BlocSelector<OtpBloc<T>, OtpState<T>, bool>(
      selector: (state) => state.canResend,
      builder: (context, canResend) {
        return Text.rich(
          TextSpan(
            style: typography.regularNormal.copyWith(
              fontSize: 14.rfs,
              color: colors.textMuted,
            ),
            children: [
              TextSpan(text: '${'otp.not_received'.tr()} '),
              TextSpan(
                text: 'otp.send_again'.tr(),
                style: TextStyle(
                  color: canResend ? colors.primary : colors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
                recognizer: canResend
                    ? (TapGestureRecognizer()
                        ..onTap = () => context.read<OtpBloc<T>>().add(
                          const OtpResendRequested(),
                        ))
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }
}

// /// Remaining **resends** — the backend's `attemptsLeft`. Shown only when the
// /// server reported it and it is running low.
// ///
// /// Deliberately silent about wrong-code attempts: no OTP endpoint in the
// /// contract exposes a verification-attempt counter, and inventing one would
// /// put a number on screen the backend never agreed to.
// class _OtpAttemptsHint<T> extends StatelessWidget {
//   const _OtpAttemptsHint();

//   /// Below this, the user is close enough to lockout to warrant a warning.
//   static const int _warnAtOrBelow = 2;

//   @override
//   Widget build(BuildContext context) {
//     final colors = context.appColors;
//     final typography = context.appTypography;

//     return BlocSelector<OtpBloc<T>, OtpState<T>, int>(
//       selector: (state) => state.cooldown.resendsLeft,
//       builder: (context, resendsLeft) {
//         if (resendsLeft < 0 || resendsLeft > _warnAtOrBelow) {
//           return const SizedBox.shrink();
//         }
//         return Padding(
//           padding: EdgeInsetsDirectional.only(
//             top: responsiveDimension(AppSpacing.sm),
//           ),
//           child: Text(
//             'otp.resends_left'.plural(resendsLeft),
//             style: typography.smallNormal.copyWith(color: colors.textMuted),
//           ),
//         );
//       },
//     );
//   }
// }
