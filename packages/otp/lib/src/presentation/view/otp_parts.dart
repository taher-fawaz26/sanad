/// The OTP screen's building blocks — one implementation of each, shared by
/// every visual style.
///
/// Each part owns its binding to [OtpBloc] (which slice of state it watches,
/// which event it dispatches); the *look* is passed in by the layout that
/// arranges them. That split is deliberate: adding a style must never mean
/// re-deriving "when is the resend link tappable" or "which phase is a field
/// error", so those answers live here, exactly once.
///
/// ### Two error slots, never merged
///
/// A *code* error (wrong, expired) belongs under the field — the user can fix
/// it by retyping. A *dispatch* error (address taken, purpose forbidden,
/// server down) belongs in a banner above the content — retyping cannot help.
/// A cooldown is neither: it is the countdown.
library;

import 'package:app_animations/app_animations.dart';
import 'package:core/core.dart' show Failure;
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/localization.dart';
import 'package:otp/src/presentation/bloc/otp/otp_bloc.dart';
import 'package:otp/src/presentation/config/otp_flow_config.dart';

// ── Dispatch banner ──────────────────────────────────────────────────────────

/// Delivery/session errors. Occupies no space when there is nothing to say.
///
/// Identical in both styles: neither Figma specifies this state (it is a
/// failure the designs don't draw), so there is nothing to diverge on.
class OtpDispatchBanner<T> extends StatelessWidget {
  const OtpDispatchBanner({required this.config, super.key});

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

        final banner = failure == null
            ? const SizedBox.shrink()
            : _buildBanner(context, colors, typography, phase, failure);

        // Opt-in: crossfade the banner in/out (client OAuth OTP page). Every
        // other consumer returns the banner directly, unchanged.
        if (!config.animateBanner) return banner;
        return AppStateTransition<bool>(
          value: failure != null,
          builder: (context, _) => banner,
        );
      },
    );
  }

  Widget _buildBanner(
    BuildContext context,
    AppColors colors,
    AppTypography typography,
    OtpPhase phase,
    Failure failure,
  ) {
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
                style: typography.regularNormal.copyWith(color: colors.error),
              ),
            ),
            if (phase is OtpDispatchFailed) ...[
              SizedBox(width: AppSpacing.sm),
              GestureDetector(
                onTap: () =>
                    context.read<OtpBloc<T>>().add(const OtpDispatchRetried()),
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
  }
}

// ── Header ───────────────────────────────────────────────────────────────────

/// Title + "we sent a code to `<destination>`" line, with an optional inline
/// "Change" affordance.
///
/// The destination is read from the bloc (it can change mid-flow) and is
/// wrapped in an LTR isolate so a leading `+` on a phone number renders at
/// the visual start under an RTL paragraph (SAN-770).
class OtpHeader<T> extends StatelessWidget {
  const OtpHeader({
    required this.config,
    required this.defaultTitleKey,
    required this.defaultSubtitleKey,
    required this.titleStyle,
    required this.subtitleStyle,
    required this.destinationStyle,
    required this.changeStyle,
    required this.gap,
    required this.alignment,
    super.key,
    this.destinationSuffix = '',
  });

  final OtpFlowConfig<T> config;

  /// Localization key used when the flow supplies no `titleBuilder`.
  final String defaultTitleKey;

  /// Localization key used when the flow supplies no `subtitleBuilder`.
  final String defaultSubtitleKey;

  final TextStyle titleStyle;
  final TextStyle subtitleStyle;

  /// Applied to the destination run inside the subtitle.
  final TextStyle destinationStyle;

  /// Applied to the trailing "Change" run (only rendered when the flow
  /// supplies `onChangeDestination`).
  final TextStyle changeStyle;

  /// Punctuation printed straight after the destination. The client frame
  /// ends the sentence with a full stop; the provider frame runs the
  /// "Change" affordance on without one.
  final String destinationSuffix;

  final double gap;
  final CrossAxisAlignment alignment;

  bool get _isCentered => alignment == CrossAxisAlignment.center;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OtpBloc<T>, OtpState<T>>(
      buildWhen: (p, c) => p.displayDestination != c.displayDestination,
      builder: (context, state) {
        final subtitle =
            config.subtitleBuilder?.call(context, config) ??
            defaultSubtitleKey.tr();
        final destination = state.displayDestination;

        return Column(
          crossAxisAlignment: alignment,
          children: [
            Text(
              config.titleBuilder?.call(context, config) ??
                  defaultTitleKey.tr(),
              textAlign: _isCentered ? TextAlign.center : TextAlign.start,
              style: titleStyle,
            ),
            SizedBox(height: gap),
            Text.rich(
              TextSpan(
                style: subtitleStyle,
                children: [
                  TextSpan(text: '$subtitle '),
                  if (destination.isNotEmpty) ...[
                    TextSpan(
                      text: destination.ltrIsolated,
                      style: destinationStyle,
                    ),
                    if (destinationSuffix.isNotEmpty)
                      TextSpan(text: destinationSuffix),
                  ],
                  if (config.onChangeDestination != null) ...[
                    const TextSpan(text: ' '),
                    TextSpan(
                      text: 'common.change'.tr(),
                      style: changeStyle,
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => _changeDestination(context),
                    ),
                  ],
                ],
              ),
              textAlign: _isCentered ? TextAlign.center : TextAlign.start,
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

// ── Code field ───────────────────────────────────────────────────────────────

/// The six-cell code input.
///
/// One control (`AppOtpField`) in both styles — only its cell metrics and the
/// caption style under it differ.
class OtpCodeField<T> extends StatelessWidget {
  const OtpCodeField({
    required this.config,
    required this.controller,
    required this.metrics,
    required this.errorTextStyle,
    required this.invalidCodeKey,
    super.key,
  });

  final OtpFlowConfig<T> config;
  final TextEditingController controller;
  final AppOtpFieldMetrics metrics;

  /// `null` leaves `AppOtpField`'s own shared field-error style in place.
  final TextStyle? errorTextStyle;

  /// Localization key for a rejected code — the styles word this differently.
  final String invalidCodeKey;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OtpBloc<T>, OtpState<T>>(
      buildWhen: (p, c) => p.phase != c.phase,
      builder: (context, state) {
        final bloc = context.read<OtpBloc<T>>();
        final errorText = switch (state.phase) {
          OtpInvalidCode() => invalidCodeKey.tr(),
          OtpExpiredPhase() => 'otp.expired_code'.tr(),
          _ => null,
        };
        final busy = state.phase is OtpVerifying || state.phase is OtpSending;

        // Opt-in subtle shake, OTP field only, on an invalid/expired code
        // (client OAuth OTP page). The trigger changes per rejected attempt
        // (phase + the rejected code) so a fresh wrong code re-fires it while
        // an unrelated rebuild does not; `appShake` no-ops under reduced
        // motion — the inline error text still conveys the failure.
        final shakeTrigger = config.animateContent && errorText != null
            ? '${state.phase.runtimeType}:${state.code}'
            : null;

        return Center(
          child: AppOtpField(
            controller: controller,
            length: config.length,
            metrics: metrics,
            autofocus: config.autofocus,
            enabled: !busy,
            errorText: errorText,
            errorTextStyle: errorTextStyle,
            onChanged: (value) => bloc.add(OtpCodeChanged(value)),
            onCompleted: config.autoSubmit
                ? (value) => bloc.add(OtpSubmitted(value))
                : null,
            onSubmitted: (value) => bloc.add(OtpSubmitted(value)),
          ).appShake(context, trigger: shakeTrigger),
        );
      },
    );
  }
}

// ── Verify action ────────────────────────────────────────────────────────────

/// The submit CTA. Enabled only on a full code that is not mid-flight.
class OtpVerifyButton<T> extends StatelessWidget {
  const OtpVerifyButton({
    required this.config,
    required this.defaultLabelKey,
    super.key,
  });

  final OtpFlowConfig<T> config;

  /// Localization key used when the flow supplies no `verifyLabel`.
  final String defaultLabelKey;

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
          label: config.verifyLabel ?? defaultLabelKey.tr(),
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

/// `mm:ss` (provider) or `m:ss` (client) — the two designs print the same
/// number differently.
String formatOtpSeconds(int seconds, {required bool padMinutes}) {
  final minutes = seconds ~/ 60;
  final m = padMinutes ? minutes.toString().padLeft(2, '0') : '$minutes';
  final s = (seconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

/// The remaining-cooldown readout.
///
/// [labelKey] is a `{time}`-interpolated key (the client's "Resend code in
/// 0:45" caption); pass `null` for the provider's bare "01:30". Renders
/// nothing once the countdown reaches zero.
class OtpCountdown<T> extends StatelessWidget {
  const OtpCountdown({
    required this.style,
    required this.padMinutes,
    super.key,
    this.labelKey,
    this.padding,
    this.whenIdle = const SizedBox.shrink(),
  });

  final TextStyle style;
  final bool padMinutes;
  final String? labelKey;

  /// Applied **only** while the countdown is on screen, so a layout that
  /// stacks it between two other sections doesn't leave its own gutters
  /// behind once the cooldown is spent.
  final EdgeInsetsGeometry? padding;

  /// What to render while no cooldown is running.
  final Widget whenIdle;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<OtpBloc<T>, OtpState<T>, int>(
      selector: (state) => state.secondsRemaining,
      builder: (context, seconds) {
        if (seconds <= 0) return whenIdle;
        final time = formatOtpSeconds(seconds, padMinutes: padMinutes);
        final key = labelKey;
        final label = Center(
          child: Text(
            key == null ? time : key.tr(namedArgs: {'time': time}),
            style: style,
          ),
        );
        final inset = padding;
        return inset == null ? label : Padding(padding: inset, child: label);
      },
    );
  }
}

/// "Didn't receive the code? **Resend**".
///
/// Always rendered by the provider layout (the link greys out while the
/// cooldown runs); rendered by the client layout only once the cooldown is
/// spent, because its Figma swaps this row in for the countdown caption.
class OtpResendRow<T> extends StatelessWidget {
  const OtpResendRow({
    required this.promptKey,
    required this.actionKey,
    required this.promptStyle,
    required this.actionStyle,
    required this.disabledActionStyle,
    required this.centered,
    super.key,
  });

  final String promptKey;
  final String actionKey;
  final TextStyle promptStyle;

  /// Applied to the action run while a resend is allowed.
  final TextStyle actionStyle;

  /// Applied while the cooldown blocks a resend.
  final TextStyle disabledActionStyle;

  final bool centered;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<OtpBloc<T>, OtpState<T>, bool>(
      selector: (state) => state.canResend,
      builder: (context, canResend) {
        return Text.rich(
          TextSpan(
            style: promptStyle,
            children: [
              TextSpan(text: '${promptKey.tr()} '),
              TextSpan(
                text: actionKey.tr(),
                style: canResend ? actionStyle : disabledActionStyle,
                recognizer: canResend
                    ? (TapGestureRecognizer()
                        ..onTap = () => context.read<OtpBloc<T>>().add(
                          const OtpResendRequested(),
                        ))
                    : null,
              ),
            ],
          ),
          textAlign: centered ? TextAlign.center : TextAlign.start,
        );
      },
    );
  }
}

/// "3 resends left" — the backend's `attemptsLeft` for the live session.
///
/// Occupies no space until the server has actually told us a number: a
/// negative `resendsLeft` is the "not reported" sentinel, and inventing a
/// count there would be worse than saying nothing.
///
/// Deliberately *not* a wrong-code counter — no endpoint in the contract
/// exposes remaining verification attempts, so the copy says "resends".
class OtpResendsLeft<T> extends StatelessWidget {
  const OtpResendsLeft({
    required this.style,
    required this.centered,
    super.key,
    this.padding,
  });

  final TextStyle style;
  final bool centered;

  /// Applied **only** when there is a count to show, so a layout that stacks
  /// this between two sections doesn't leave its own gutter behind while the
  /// server stays silent.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<OtpBloc<T>, OtpState<T>, int>(
      selector: (state) => state.cooldown.resendsLeft,
      builder: (context, resendsLeft) {
        if (resendsLeft < 0) return const SizedBox.shrink();
        final text = _copy(resendsLeft);
        if (text == null) return const SizedBox.shrink();
        final label = Text(
          text,
          style: style,
          textAlign: centered ? TextAlign.center : TextAlign.start,
        );
        final inset = padding;
        return inset == null ? label : Padding(padding: inset, child: label);
      },
    );
  }

  /// The pluralized caption, or `null` when it cannot be resolved.
  ///
  /// This is the only part that needs a *plural* key, and unlike `.tr()` —
  /// which falls back to the raw key — `plural()` reads the locale off the
  /// `Localization` singleton and throws outright when none is loaded. A hint
  /// about how many resends remain must never be able to take down the
  /// verification screen around it, so an unresolvable count renders as
  /// nothing at all.
  String? _copy(int resendsLeft) {
    try {
      return 'otp.resends_left'.plural(resendsLeft);
    } on Object {
      return null;
    }
  }
}
