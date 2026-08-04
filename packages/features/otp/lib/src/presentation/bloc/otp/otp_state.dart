part of 'otp_bloc.dart';

/// Async sub-state of the verification attempt. Kept separate from the
/// always-present fields on [OtpState] (destination, timer, code) so the two
/// axes cannot be combined into an impossible state.
sealed class OtpPhase extends Equatable {
  const OtpPhase();

  @override
  List<Object?> get props => [];
}

class OtpIdle extends OtpPhase {
  const OtpIdle();
}

class OtpSending extends OtpPhase {
  const OtpSending();
}

class OtpAwaitingInput extends OtpPhase {
  const OtpAwaitingInput();
}

class OtpVerifying extends OtpPhase {
  const OtpVerifying();
}

class OtpVerifiedPhase extends OtpPhase {
  const OtpVerifiedPhase();
}

class OtpInvalidCode extends OtpPhase {
  const OtpInvalidCode(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

class OtpExpiredPhase extends OtpPhase {
  const OtpExpiredPhase();
}

class OtpFailurePhase extends OtpPhase {
  const OtpFailurePhase(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

class OtpState<T> extends Equatable {
  const OtpState({
    this.phase = const OtpIdle(),
    this.code = '',
    this.destination = '',
    this.channel = OtpChannel.email,
    this.secondsRemaining = 0,
    this.canResend = false,
    this.maskedDestination,
    this.verifiedData,
  });

  final OtpPhase phase;
  final String code;
  final String destination;
  final OtpChannel channel;
  final int secondsRemaining;
  final bool canResend;
  final String? maskedDestination;

  /// Set only once [phase] is `OtpVerifiedPhase` — the value
  /// `OtpVerifier.verifyCode` resolved to.
  final T? verifiedData;

  OtpState<T> copyWith({
    OtpPhase? phase,
    String? code,
    String? destination,
    OtpChannel? channel,
    int? secondsRemaining,
    bool? canResend,
    String? maskedDestination,
    T? verifiedData,
  }) {
    return OtpState<T>(
      phase: phase ?? this.phase,
      code: code ?? this.code,
      destination: destination ?? this.destination,
      channel: channel ?? this.channel,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      canResend: canResend ?? this.canResend,
      maskedDestination: maskedDestination ?? this.maskedDestination,
      verifiedData: verifiedData ?? this.verifiedData,
    );
  }

  @override
  List<Object?> get props => [
    phase,
    code,
    destination,
    channel,
    secondsRemaining,
    canResend,
    maskedDestination,
    verifiedData,
  ];
}
