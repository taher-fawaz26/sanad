import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:core/core.dart' hide AppDurations;
import 'package:design_system/design_system.dart' show AppDurations;
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otp/src/domain/entities/otp_cooldown.dart';
import 'package:otp/src/domain/enums/otp_channel.dart';
import 'package:otp/src/presentation/config/otp_flow_config.dart';

part 'otp_event.dart';
part 'otp_state.dart';

/// Codes the caller's `OtpVerifier` can use on a [Failure] to signal the code
/// expired rather than being merely wrong. Any other code/failure is treated
/// as an invalid-code error.
const List<String> kOtpExpiredFailureCodes = ['OTP_EXPIRED', 'otp_expired'];

/// Drives a single OTP verification attempt: probe, send, countdown, submit,
/// resend, change-destination. One `OtpBloc` instance per flow invocation.
///
/// ### Read before write
///
/// OTP sessions live on the server, keyed by (account, purpose), and outlive
/// the sheet that created them. Dispatching a code unconditionally on open
/// therefore collides with any cooldown still running from an earlier attempt
/// — the backend answers 429 and the user meets an error under an empty
/// field. So the flow *probes* `OtpVerifier.cooldown()` first and only sends
/// when no session is live.
///
/// ### Cooldown is data, not an error
///
/// A rate-limit response is a normal, expected state: it means a valid code is
/// already out there. It seeds the countdown; it never renders as a failure.
class OtpBloc<T> extends Bloc<OtpEvent, OtpState<T>> {
  OtpBloc({required OtpFlowConfig<T> config, DateTime Function()? clock})
    : _config = config,
      _now = clock ?? DateTime.now,
      super(
        OtpState<T>(destination: config.destination, channel: config.channel),
      ) {
    on<OtpStarted>(_onStarted, transformer: droppable());
    on<OtpCodeChanged>(_onCodeChanged);
    on<OtpSubmitted>(_onSubmitted, transformer: droppable());
    on<OtpResendRequested>(_onResendRequested, transformer: droppable());
    on<OtpDispatchRetried>(_onDispatchRetried, transformer: droppable());
    on<OtpTimerTicked>(_onTimerTicked);
    on<OtpDestinationChanged>(_onDestinationChanged, transformer: droppable());
    on<OtpDismissed>(_onDismissed);
  }

  final OtpFlowConfig<T> _config;
  final DateTime Function() _now;
  Timer? _timer;

  // -- Lifecycle -------------------------------------------------------------

  Future<void> _onStarted(OtpStarted event, Emitter<OtpState<T>> emit) async {
    if (!_config.autoSendOnStart) {
      // The caller already sent a code before opening the flow, so there IS a
      // live session — read its cooldown rather than assuming one.
      emit(state.copyWith(phase: const OtpAwaitingInput()));
      await _syncCooldown(emit, assumeJustSent: true);
      return;
    }
    await _bootstrap(emit);
  }

  /// Probe, then dispatch only if nothing is live.
  Future<void> _bootstrap(Emitter<OtpState<T>> emit) async {
    emit(state.copyWith(phase: const OtpSending()));

    if (_config.probeCooldownOnStart) {
      final probed = await _probeCooldown();
      if (isClosed) return;
      if (probed != null && probed.isLiveCooldown) {
        // A code is already out there and still valid — show the countdown and
        // let the user type it. Sending again would only earn a 429.
        _applyCooldown(emit, probed, phase: const OtpAwaitingInput());
        return;
      }
      // Anything else — including `canResend: false` with nothing left to wait
      // for, which is how every one of these endpoints reports "no session
      // exists yet" — falls through to the dispatch below. Reading that shape
      // as a live cooldown is what previously stranded the user on an OTP
      // screen where no code had been sent, no countdown ran, and the resend
      // link was permanently dead (SAN contact-verification dead end).
    }

    await _dispatch(emit, resend: false);
  }

  // -- Dispatch --------------------------------------------------------------

  Future<void> _dispatch(
    Emitter<OtpState<T>> emit, {
    required bool resend,
  }) async {
    emit(
      state.copyWith(
        phase: resend ? state.phase : const OtpSending(),
        isResending: resend,
      ),
    );

    final task = resend
        ? _config.verifier.resendCode()
        : _config.verifier.requestCode();
    final result = await task.run();

    if (isClosed) return;

    await result.match(
      (failure) async {
        if (failure is RateLimitFailure) {
          // Not an error: a live code already exists. Show its countdown.
          await _syncCooldown(emit, assumeJustSent: true);
          if (isClosed) return;
          emit(
            state.copyWith(
              phase: const OtpAwaitingInput(),
              isResending: false,
            ),
          );
          return;
        }
        emit(
          state.copyWith(
            phase: OtpDispatchFailed(failure),
            isResending: false,
          ),
        );
      },
      (delivery) async {
        emit(
          state.copyWith(
            phase: const OtpAwaitingInput(),
            isResending: false,
            maskedDestination: delivery.maskedDestination,
          ),
        );
        await _syncCooldown(emit, assumeJustSent: true);
      },
    );
  }

  Future<void> _onResendRequested(
    OtpResendRequested event,
    Emitter<OtpState<T>> emit,
  ) async {
    if (!state.canResend) return;
    await _dispatch(emit, resend: true);
  }

  Future<void> _onDispatchRetried(
    OtpDispatchRetried event,
    Emitter<OtpState<T>> emit,
  ) async {
    if (state.phase is! OtpDispatchFailed) return;
    await _bootstrap(emit);
  }

  Future<void> _onDestinationChanged(
    OtpDestinationChanged event,
    Emitter<OtpState<T>> emit,
  ) async {
    _timer?.cancel();
    // A new destination is a new session: drop every trace of the old one
    // rather than letting a stale error, code or countdown bleed across.
    emit(
      state.copyWith(
        destination: event.destination,
        code: '',
        phase: const OtpIdle(),
        cooldown: OtpCooldown.unknown,
        isResending: false,
        clearCooldownEndsAt: true,
        clearMaskedDestination: true,
        clearVerifiedData: true,
      ),
    );
    await _bootstrap(emit);
  }

  // -- Verification ----------------------------------------------------------

  void _onCodeChanged(OtpCodeChanged event, Emitter<OtpState<T>> emit) {
    if (state.phase is OtpVerifying || state.phase is OtpVerifiedPhase) return;
    final clearsError =
        state.phase is OtpInvalidCode || state.phase is OtpExpiredPhase;
    emit(
      state.copyWith(
        code: event.code,
        phase: clearsError ? const OtpAwaitingInput() : state.phase,
      ),
    );
  }

  Future<void> _onSubmitted(
    OtpSubmitted event,
    Emitter<OtpState<T>> emit,
  ) async {
    if (state.phase is OtpVerifying || state.phase is OtpVerifiedPhase) return;

    final code = event.code ?? state.code;
    if (code.length != _config.length) return;

    emit(state.copyWith(code: code, phase: const OtpVerifying()));
    final result = await _config.verifier.verifyCode(code).run();

    if (isClosed) return;

    result.match(
      (failure) {
        emit(state.copyWith(phase: _verifyFailurePhase(failure)));
      },
      (data) {
        _timer?.cancel();
        emit(
          state.copyWith(phase: const OtpVerifiedPhase(), verifiedData: data),
        );
      },
    );
  }

  /// Maps by failure *type*, never by parsing backend prose.
  ///
  /// Only ever called from [_onSubmitted] against `verifyCode()`'s result, so
  /// this is scoped to "was the submitted code accepted?" — a verify-code
  /// endpoint has no business rule to enforce beyond that, so a plain
  /// [BusinessRuleFailure] here means the same thing a [ValidationFailure]
  /// does: the code was rejected. (A hand-written backend rejection — e.g.
  /// `{"message": "Invalid code"}` — maps to [BusinessRuleFailure], not
  /// [ValidationFailure], because `ErrorMapper` only produces the latter for
  /// a class-validator-shaped `message` array; treating them differently here
  /// previously routed a wrong-code response into the dispatch banner instead
  /// of the field.)
  OtpPhase _verifyFailurePhase(Failure failure) {
    if (kOtpExpiredFailureCodes.contains(failure.code)) {
      return const OtpExpiredPhase();
    }
    if (failure is ConflictFailure) return OtpConflict(failure);
    if (failure is ValidationFailure || failure is BusinessRuleFailure) {
      return OtpInvalidCode(failure);
    }
    // Anything else (network, server, auth) is a delivery-side problem the
    // user cannot fix by retyping — it belongs in the banner.
    return OtpDispatchFailed(failure);
  }

  // -- Cooldown --------------------------------------------------------------

  /// Reads server cooldown state, or `null` when there is no answer to be had
  /// — either this flow exposes no endpoint, or the probe failed. Both mean
  /// "unknown", and callers must never turn unknown into a block.
  Future<OtpCooldown?> _probeCooldown() async {
    final task = _config.verifier.cooldown();
    if (task == null) return null;
    final result = await task.run();
    return result.fold((_) => null, (value) => value);
  }

  /// Refreshes the countdown from the server, falling back to
  /// [OtpFlowConfig.fallbackCooldown] when there is nothing to read but we
  /// know a code was just sent.
  Future<void> _syncCooldown(
    Emitter<OtpState<T>> emit, {
    required bool assumeJustSent,
  }) async {
    final probed = await _probeCooldown();
    if (isClosed) return;

    // The server is authoritative whenever it answered - including when it
    // says the user may resend immediately. Overriding that with a local
    // fallback would invent a cooldown the backend is not enforcing.
    if (probed != null) {
      _applyCooldown(emit, probed);
      return;
    }
    if (!assumeJustSent) {
      _applyCooldown(emit, OtpCooldown.unknown);
      return;
    }
    // No answer, but a code definitely went out: fall back so the user is not
    // handed an immediately-tappable resend.
    _applyCooldown(
      emit,
      OtpCooldown(
        canResend: false,
        remainingSeconds: _config.fallbackCooldown.inSeconds,
      ),
    );
  }

  void _applyCooldown(
    Emitter<OtpState<T>> emit,
    OtpCooldown cooldown, {
    OtpPhase? phase,
  }) {
    _timer?.cancel();

    final seconds = cooldown.remainingSeconds;
    final running = !cooldown.canResend && seconds > 0;

    // Seeded synchronously, not via a dispatched tick event: routing the first
    // value through the event loop leaves a frame rendering "00:00".
    emit(
      state.copyWith(
        phase: phase ?? state.phase,
        cooldown: cooldown,
        cooldownEndsAt: running ? _now().add(Duration(seconds: seconds)) : null,
        clearCooldownEndsAt: !running,
      ),
    );

    if (running) {
      _timer = Timer.periodic(AppDurations.otpTimerTick, (_) {
        if (isClosed) return;
        add(const OtpTimerTicked());
      });
    }
  }

  void _onTimerTicked(OtpTimerTicked event, Emitter<OtpState<T>> emit) {
    final endsAt = state.cooldownEndsAt;
    if (endsAt == null) {
      _timer?.cancel();
      return;
    }

    // Recomputed from the anchor rather than decremented, so a suspended app
    // resumes with the correct remainder instead of a frozen one.
    final remaining = endsAt.difference(_now()).inSeconds;
    if (remaining <= 0) {
      _timer?.cancel();
      emit(
        state.copyWith(
          cooldown: state.cooldown.copyWith(
            canResend: true,
            remainingSeconds: 0,
          ),
          clearCooldownEndsAt: true,
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        cooldown: state.cooldown.copyWith(remainingSeconds: remaining),
      ),
    );
  }

  void _onDismissed(OtpDismissed event, Emitter<OtpState<T>> emit) {
    _timer?.cancel();
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
