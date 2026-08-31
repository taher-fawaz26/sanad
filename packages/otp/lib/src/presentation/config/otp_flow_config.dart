import 'package:core/core.dart' show Failure;
import 'package:design_system/design_system.dart'
    show AppDurations, kDefaultOtpLength;
import 'package:flutter/widgets.dart';
import 'package:otp/src/domain/contracts/otp_verifier.dart';
import 'package:otp/src/domain/enums/otp_channel.dart';
import 'package:otp/src/domain/enums/otp_purpose.dart';

/// How the OTP screen is hosted. The *contents* are identical either way —
/// only the surrounding container differs, so there is exactly one OTP UI.
enum OtpPresentation {
  /// Full-page route. The canonical presentation (matches the auth screen).
  page,

  /// Hosted in a `SheetNavigator` bottom sheet.
  sheet,
}

/// The single knob-set for an OTP verification run. Immutable; the common
/// call only needs `destination`, `channel`, and `verifier` — everything else
/// has a sensible default.
@immutable
class OtpFlowConfig<T> {
  const OtpFlowConfig({
    required this.channel,
    required this.destination,
    required this.verifier,
    this.purpose = OtpPurpose.custom,
    this.length = kDefaultOtpLength,
    this.fallbackCooldown = AppDurations.otpResendCooldown,
    this.probeCooldownOnStart = true,
    this.autoSendOnStart = true,
    this.autoSubmit = true,
    this.autofocus = true,
    this.showSuccessScreen = true,
    this.successAutoCloseDelay = const Duration(seconds: 2),
    this.onChangeDestination,
    this.presentation = OtpPresentation.sheet,
    this.titleBuilder,
    this.subtitleBuilder,
    this.dispatchErrorResolver,
    this.verifyLabel,
    this.pinActionToBottom = false,
  });

  /// Verify an email address. [purpose] defaults to [OtpPurpose.verifyEmail].
  const OtpFlowConfig.email({
    required this.destination,
    required this.verifier,
    this.purpose = OtpPurpose.verifyEmail,
    this.length = kDefaultOtpLength,
    this.fallbackCooldown = AppDurations.otpResendCooldown,
    this.probeCooldownOnStart = true,
    this.autoSendOnStart = true,
    this.autoSubmit = true,
    this.autofocus = true,
    this.showSuccessScreen = true,
    this.successAutoCloseDelay = const Duration(seconds: 2),
    this.onChangeDestination,
    this.presentation = OtpPresentation.sheet,
    this.titleBuilder,
    this.subtitleBuilder,
    this.dispatchErrorResolver,
    this.verifyLabel,
    this.pinActionToBottom = false,
  }) : channel = OtpChannel.email;

  /// Verify a phone number. [purpose] defaults to [OtpPurpose.verifyPhone].
  const OtpFlowConfig.phone({
    required this.destination,
    required this.verifier,
    this.purpose = OtpPurpose.verifyPhone,
    this.length = kDefaultOtpLength,
    this.fallbackCooldown = AppDurations.otpResendCooldown,
    this.probeCooldownOnStart = true,
    this.autoSendOnStart = true,
    this.autoSubmit = true,
    this.autofocus = true,
    this.showSuccessScreen = true,
    this.successAutoCloseDelay = const Duration(seconds: 2),
    this.onChangeDestination,
    this.presentation = OtpPresentation.sheet,
    this.titleBuilder,
    this.subtitleBuilder,
    this.dispatchErrorResolver,
    this.verifyLabel,
    this.pinActionToBottom = false,
  }) : channel = OtpChannel.phone;

  final OtpChannel channel;

  /// Display value shown in the subtitle (e.g. `+971 5X XXX XXXX`).
  final String destination;

  final OtpVerifier<T> verifier;
  final OtpPurpose purpose;
  final int length;

  /// Countdown used **only** when the verifier exposes no `cooldown()` — or
  /// when that probe fails after a code has demonstrably been sent.
  ///
  /// Never the primary source: a flow whose backend has a `resend-info`
  /// endpoint always shows the server's own `remainingSeconds`.
  final Duration fallbackCooldown;

  /// Whether to read `cooldown()` before dispatching. Leave true: it is what
  /// stops a reopened flow from provoking a 429 against a live session.
  final bool probeCooldownOnStart;

  /// Whether the flow sends a code on start (set false if the caller already
  /// sent one before opening the flow).
  final bool autoSendOnStart;

  /// Submit as soon as the final digit lands.
  ///
  /// Leave false where a wrong code is costly: re-editing a digit of an
  /// already-full code would otherwise re-fire verification and burn attempts
  /// (SAN-539).
  final bool autoSubmit;

  final bool autofocus;
  final bool showSuccessScreen;
  final Duration successAutoCloseDelay;

  /// Returns a new destination string, or null if the user cancelled the
  /// change. When set, a "Change" affordance is shown next to the
  /// destination.
  final Future<String?> Function(BuildContext context)? onChangeDestination;

  final OtpPresentation presentation;

  bool get presentAsSheet => presentation == OtpPresentation.sheet;

  final String Function(BuildContext context, OtpFlowConfig<T> config)?
  titleBuilder;
  final String Function(BuildContext context, OtpFlowConfig<T> config)?
  subtitleBuilder;

  /// Flow-specific copy for a delivery failure (a 409 on a taken address, a
  /// 403 on a forbidden purpose). Returning null falls back to the failure's
  /// own localized message.
  final String? Function(Failure failure)? dispatchErrorResolver;

  /// Overrides the verify button's default `otp.verify` ("Verify") label.
  ///
  /// Some flows (a linear sign-up/sign-in wizard) want "Next" instead of
  /// "Verify" — a wording choice specific to that flow's product copy, not a
  /// generic OTP-screen default other consumers (account deletion, invitation
  /// acceptance) should inherit.
  final String? verifyLabel;

  /// Pins the verify button to the bottom of the available space, with the
  /// scrollable content (icon/title/field/resend) filling everything above
  /// it, instead of flowing inline after the resend row.
  ///
  /// Defaults to `false` (today's behavior, unchanged for every existing
  /// consumer). Only turn this on when the host gives `OtpView` *bounded*
  /// height — a full-screen `Scaffold.body` — since it wraps the scrollable
  /// content in an `Expanded`, which asserts against an unbounded-height
  /// ancestor (e.g. a content-sized bottom sheet).
  final bool pinActionToBottom;
}
