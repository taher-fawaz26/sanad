import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OtpUiState extends Equatable {
  const OtpUiState({
    this.secondsRemaining = 0,
    this.otpError,
  });

  final int secondsRemaining;
  final String? otpError;

  OtpUiState copyWith({
    int? secondsRemaining,
    String? otpError,
    bool clearError = false,
  }) {
    return OtpUiState(
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      otpError: clearError ? null : (otpError ?? this.otpError),
    );
  }

  @override
  List<Object?> get props => [secondsRemaining, otpError];

  @override
  String toString() =>
      'OtpUiState(secondsRemaining: $secondsRemaining, otpError: $otpError)';
}

/// Local UI state for OTP countdown and field error.
class OtpUiCubit extends Cubit<OtpUiState> {
  OtpUiCubit() : super(const OtpUiState());

  Timer? _timer;

  void startTimer([Duration? cooldown]) {
    _timer?.cancel();
    final totalSeconds =
        (cooldown ?? AppDurations.otpResendCooldown).inSeconds;
    emit(state.copyWith(secondsRemaining: totalSeconds, clearError: true));
    _timer = Timer.periodic(AppDurations.otpTimerTick, (timer) {
      final next = state.secondsRemaining - 1;
      if (next <= 0) {
        timer.cancel();
        emit(state.copyWith(secondsRemaining: 0));
      } else {
        emit(state.copyWith(secondsRemaining: next));
      }
    });
  }

  void setError(String? error) {
    emit(state.copyWith(otpError: error, clearError: error == null));
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
