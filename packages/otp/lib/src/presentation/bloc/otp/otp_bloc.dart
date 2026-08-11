import 'dart:async';

import 'package:core/core.dart' hide AppDurations;
import 'package:design_system/design_system.dart' show AppDurations;
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otp/src/domain/enums/otp_channel.dart';
import 'package:otp/src/presentation/config/otp_flow_config.dart';

part 'otp_event.dart';
part 'otp_state.dart';

/// Codes the caller's `OtpVerifier` can use on a [Failure] to signal the code
/// expired rather than being merely wrong. Any other code/failure is treated
/// as an invalid-code error.
const List<String> kOtpExpiredFailureCodes = ['OTP_EXPIRED', 'otp_expired'];

/// Drives a single OTP verification attempt: send, countdown, submit,
/// resend, change-destination. One `OtpBloc` instance per flow invocation.
class OtpBloc<T> extends Bloc<OtpEvent, OtpState<T>> {
  OtpBloc({required OtpFlowConfig<T> config})
    : _config = config,
      super(
        OtpState<T>(
          destination: config.destination,
          channel: config.channel,
        ),
      ) {
    on<OtpStarted>(_onStarted);
    on<OtpCodeChanged>(_onCodeChanged);
    on<OtpSubmitted>(_onSubmitted);
    on<OtpResendRequested>(_onResendRequested);
    on<OtpTimerTicked>(_onTimerTicked);
    on<OtpDestinationChanged>(_onDestinationChanged);
    on<OtpDismissed>(_onDismissed);
  }

  final OtpFlowConfig<T> _config;
  Timer? _timer;

  Future<void> _onStarted(OtpStarted event, Emitter<OtpState<T>> emit) async {
    if (!_config.autoSendOnStart) {
      emit(state.copyWith(phase: const OtpAwaitingInput()));
      _startTimer();
      return;
    }
    await _requestCode(emit);
  }

  Future<void> _requestCode(Emitter<OtpState<T>> emit) async {
    emit(state.copyWith(phase: const OtpSending(), canResend: false));
    final result = await _config.verifier.requestCode().run();
    result.match(
      (failure) => emit(state.copyWith(phase: OtpFailurePhase(failure))),
      (delivery) {
        emit(
          state.copyWith(
            phase: const OtpAwaitingInput(),
            maskedDestination: delivery.maskedDestination,
          ),
        );
        _startTimer();
      },
    );
  }

  void _startTimer() {
    _timer?.cancel();
    final seconds =
        (_config.resendCooldown ?? AppDurations.otpResendCooldown).inSeconds;
    add(OtpTimerTicked(seconds));
    _timer = Timer.periodic(AppDurations.otpTimerTick, (timer) {
      final next = state.secondsRemaining - 1;
      if (next <= 0) {
        timer.cancel();
        if (!isClosed) add(const OtpTimerTicked(0));
      } else {
        if (!isClosed) add(OtpTimerTicked(next));
      }
    });
  }

  void _onTimerTicked(OtpTimerTicked event, Emitter<OtpState<T>> emit) {
    emit(
      state.copyWith(
        secondsRemaining: event.secondsRemaining,
        canResend: event.secondsRemaining <= 0,
      ),
    );
  }

  void _onCodeChanged(OtpCodeChanged event, Emitter<OtpState<T>> emit) {
    if (state.phase is OtpVerifying) return;
    emit(
      state.copyWith(
        code: event.code,
        phase: state.phase is OtpInvalidCode || state.phase is OtpFailurePhase
            ? const OtpAwaitingInput()
            : state.phase,
      ),
    );
  }

  Future<void> _onSubmitted(
    OtpSubmitted event,
    Emitter<OtpState<T>> emit,
  ) async {
    if (state.phase is OtpVerifying || state.phase is OtpVerifiedPhase) {
      return;
    }
    final code = event.code ?? state.code;
    if (code.isEmpty) return;

    emit(state.copyWith(code: code, phase: const OtpVerifying()));
    final result = await _config.verifier.verifyCode(code).run();
    result.match(
      (failure) {
        final expired = kOtpExpiredFailureCodes.contains(failure.code);
        emit(
          state.copyWith(
            phase: expired ? const OtpExpiredPhase() : OtpInvalidCode(failure),
          ),
        );
      },
      (data) {
        _timer?.cancel();
        emit(
          state.copyWith(phase: const OtpVerifiedPhase(), verifiedData: data),
        );
      },
    );
  }

  Future<void> _onResendRequested(
    OtpResendRequested event,
    Emitter<OtpState<T>> emit,
  ) async {
    if (!state.canResend) return;
    await _requestCode(emit);
  }

  Future<void> _onDestinationChanged(
    OtpDestinationChanged event,
    Emitter<OtpState<T>> emit,
  ) async {
    emit(state.copyWith(destination: event.destination, code: ''));
    await _requestCode(emit);
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
