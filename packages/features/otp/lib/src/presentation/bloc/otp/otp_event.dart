part of 'otp_bloc.dart';

sealed class OtpEvent extends Equatable {
  const OtpEvent();

  @override
  List<Object?> get props => [];
}

/// Fired once when the flow mounts. Triggers the initial send when
/// [OtpFlowConfig.autoSendOnStart] is true, then starts the countdown.
class OtpStarted extends OtpEvent {
  const OtpStarted();
}

class OtpCodeChanged extends OtpEvent {
  const OtpCodeChanged(this.code);

  final String code;

  @override
  List<Object?> get props => [code];
}

/// Submit the current code — fired by the Verify button or, when
/// `OtpFlowConfig.autoSubmit` is true, by `AppOtpField.onCompleted`.
class OtpSubmitted extends OtpEvent {
  const OtpSubmitted([this.code]);

  /// Overrides the bloc's stored code (used by auto-submit, which hands the
  /// completed value straight from the field).
  final String? code;

  @override
  List<Object?> get props => [code];
}

class OtpResendRequested extends OtpEvent {
  const OtpResendRequested();
}

class OtpTimerTicked extends OtpEvent {
  const OtpTimerTicked(this.secondsRemaining);

  final int secondsRemaining;

  @override
  List<Object?> get props => [secondsRemaining];
}

/// The destination changed (e.g. user tapped "Change" and entered a new
/// email/phone). Re-arms the send + timer against the new destination.
class OtpDestinationChanged extends OtpEvent {
  const OtpDestinationChanged(this.destination);

  final String destination;

  @override
  List<Object?> get props => [destination];
}

class OtpDismissed extends OtpEvent {
  const OtpDismissed();
}
