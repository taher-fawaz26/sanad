import 'package:design_system/design_system.dart' show kDefaultOtpLength;
import 'package:flutter/widgets.dart';
import 'package:otp/src/domain/contracts/otp_verifier.dart';
import 'package:otp/src/domain/enums/otp_channel.dart';
import 'package:otp/src/domain/enums/otp_purpose.dart';

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
    this.resendCooldown,
    this.autoSendOnStart = true,
    this.autoSubmit = true,
    this.showSuccessScreen = true,
    this.successAutoCloseDelay = const Duration(seconds: 2),
    this.onChangeDestination,
    this.presentAsSheet = true,
    this.titleBuilder,
    this.subtitleBuilder,
  });

  /// Verify an email address. [purpose] defaults to [OtpPurpose.verifyEmail].
  const OtpFlowConfig.email({
    required this.destination,
    required this.verifier,
    this.purpose = OtpPurpose.verifyEmail,
    this.length = kDefaultOtpLength,
    this.resendCooldown,
    this.autoSendOnStart = true,
    this.autoSubmit = true,
    this.showSuccessScreen = true,
    this.successAutoCloseDelay = const Duration(seconds: 2),
    this.onChangeDestination,
    this.presentAsSheet = true,
    this.titleBuilder,
    this.subtitleBuilder,
  }) : channel = OtpChannel.email;

  /// Verify a phone number. [purpose] defaults to [OtpPurpose.verifyPhone].
  const OtpFlowConfig.phone({
    required this.destination,
    required this.verifier,
    this.purpose = OtpPurpose.verifyPhone,
    this.length = kDefaultOtpLength,
    this.resendCooldown,
    this.autoSendOnStart = true,
    this.autoSubmit = true,
    this.showSuccessScreen = true,
    this.successAutoCloseDelay = const Duration(seconds: 2),
    this.onChangeDestination,
    this.presentAsSheet = true,
    this.titleBuilder,
    this.subtitleBuilder,
  }) : channel = OtpChannel.phone;

  final OtpChannel channel;

  /// Display value shown in the subtitle (e.g. `+20 123 456 7890`).
  final String destination;

  final OtpVerifier<T> verifier;
  final OtpPurpose purpose;
  final int length;

  /// Defaults to `AppDurations.otpResendCooldown` when null.
  final Duration? resendCooldown;

  /// Whether `requestCode()` fires automatically when the flow starts (set
  /// false if the caller already sent the code before opening the flow).
  final bool autoSendOnStart;

  final bool autoSubmit;
  final bool showSuccessScreen;
  final Duration successAutoCloseDelay;

  /// Returns a new destination string, or null if the user cancelled the
  /// change. When set, a "Change" affordance is shown next to the
  /// destination.
  final Future<String?> Function(BuildContext context)? onChangeDestination;

  /// True (default) presents via `SheetNavigator`; false pushes a plain page
  /// route instead.
  final bool presentAsSheet;

  final String Function(BuildContext context, OtpFlowConfig<T> config)?
  titleBuilder;
  final String Function(BuildContext context, OtpFlowConfig<T> config)?
  subtitleBuilder;
}
