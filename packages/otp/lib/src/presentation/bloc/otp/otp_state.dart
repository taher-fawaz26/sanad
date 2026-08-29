part of 'otp_bloc.dart';

/// Async sub-state of the verification attempt. Kept separate from the
/// always-present fields on [OtpState] (destination, cooldown, code) so the
/// two axes cannot be combined into an impossible state.
///
/// Note what is deliberately *absent*: a cooldown phase. A live cooldown is
/// data, not a mode — the previously issued code is still valid, so the field
/// stays open for input while the countdown runs.
sealed class OtpPhase extends Equatable {
  const OtpPhase();

  @override
  List<Object?> get props => [];
}

class OtpIdle extends OtpPhase {
  const OtpIdle();
}

/// Probing the cooldown and/or dispatching a code.
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

/// The submitted code was rejected. Renders **under the field**.
class OtpInvalidCode extends OtpPhase {
  const OtpInvalidCode(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

/// The submitted code expired or was already consumed. Renders under the
/// field, and promotes the resend affordance.
class OtpExpiredPhase extends OtpPhase {
  const OtpExpiredPhase();
}

/// The code could not be *delivered* — a bad target, a forbidden purpose, a
/// server outage. Nothing to do with what the user typed, so this renders in
/// the banner slot above the title, never as a field error.
class OtpDispatchFailed extends OtpPhase {
  const OtpDispatchFailed(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

/// The target was claimed by someone else while the code was outstanding
/// (HTTP 409). Terminal: the flow closes with `OtpFailed`.
class OtpConflict extends OtpPhase {
  const OtpConflict(this.failure);

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
    this.cooldown = OtpCooldown.unknown,
    this.cooldownEndsAt,
    this.isResending = false,
    this.maskedDestination,
    this.verifiedData,
  });

  final OtpPhase phase;
  final String code;
  final String destination;
  final OtpChannel channel;

  /// Server-reported resend state. Seeded from the verifier's `resend-info`
  /// probe, never from a hardcoded client-side duration.
  final OtpCooldown cooldown;

  /// Absolute instant the cooldown lapses. Ticking against a wall-clock
  /// anchor (rather than decrementing a counter) keeps the countdown honest
  /// across app backgrounding.
  final DateTime? cooldownEndsAt;

  final bool isResending;
  final String? maskedDestination;

  /// Set only once [phase] is `OtpVerifiedPhase` — the value
  /// `OtpVerifier.verifyCode` resolved to.
  final T? verifiedData;

  int get secondsRemaining => cooldown.remainingSeconds;

  /// Resend is offered only when the server allows it *and* nothing else is
  /// in flight — this is the single guard against double-dispatch.
  bool get canResend =>
      cooldown.canResend &&
      !isResending &&
      phase is! OtpVerifying &&
      phase is! OtpSending &&
      phase is! OtpVerifiedPhase;

  /// The destination as it should be shown: the backend's masked form when it
  /// supplied one, otherwise what the caller passed in.
  String get displayDestination => maskedDestination ?? destination;

  OtpState<T> copyWith({
    OtpPhase? phase,
    String? code,
    String? destination,
    OtpChannel? channel,
    OtpCooldown? cooldown,
    DateTime? cooldownEndsAt,
    bool? isResending,
    String? maskedDestination,
    T? verifiedData,
    bool clearCooldownEndsAt = false,
    bool clearMaskedDestination = false,
    bool clearVerifiedData = false,
  }) {
    return OtpState<T>(
      phase: phase ?? this.phase,
      code: code ?? this.code,
      destination: destination ?? this.destination,
      channel: channel ?? this.channel,
      cooldown: cooldown ?? this.cooldown,
      cooldownEndsAt: clearCooldownEndsAt
          ? null
          : (cooldownEndsAt ?? this.cooldownEndsAt),
      isResending: isResending ?? this.isResending,
      maskedDestination: clearMaskedDestination
          ? null
          : (maskedDestination ?? this.maskedDestination),
      verifiedData: clearVerifiedData
          ? null
          : (verifiedData ?? this.verifiedData),
    );
  }

  @override
  List<Object?> get props => [
    phase,
    code,
    destination,
    channel,
    cooldown,
    cooldownEndsAt,
    isResending,
    maskedDestination,
    verifiedData,
  ];
}
