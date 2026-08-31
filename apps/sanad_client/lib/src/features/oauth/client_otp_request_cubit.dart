import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Drives the "Next" step on the OAuth Email/Phone screens: dispatches the
/// unified client OTP (`POST auth/client/request-otp`) and reports whether the
/// UI may proceed to the shared OTP screen.
///
/// Per the backend contract the screen navigates to OTP **only** after a code
/// is (or already is) live:
/// - success → [ClientOtpRequestReady];
/// - `429` ([RateLimitFailure]) → also [ClientOtpRequestReady]: a valid code
///   is already out there, so the OTP screen shows its countdown rather than
///   re-sending (the screen is configured with `autoSendOnStart: false`);
/// - any other failure (`400` bad identifier, `503` delivery failed, network)
///   → [ClientOtpRequestFailure]; the screen surfaces it and does **not**
///   navigate.
class ClientOtpRequestCubit extends Cubit<ClientOtpRequestState> {
  /// Creates a [ClientOtpRequestCubit].
  ClientOtpRequestCubit(this._requestOtp)
    : super(const ClientOtpRequestInitial());

  final RequestClientOtpUseCase _requestOtp;

  /// Dispatches the client OTP for [method]/[value] and emits whether the UI
  /// may proceed to the shared OTP screen. Ignores re-entry while in flight.
  Future<void> request({
    required ClientAuthMethod method,
    required String value,
  }) async {
    if (state is ClientOtpRequestInProgress) return;
    emit(const ClientOtpRequestInProgress());

    final result = await _requestOtp(
      ClientOtpParams(method: method, value: value),
    ).run();

    if (isClosed) return;
    result.match(
      (failure) {
        // A live code already exists — proceed and let the OTP screen show the
        // server countdown instead of treating the rate limit as an error.
        if (failure is RateLimitFailure) {
          emit(const ClientOtpRequestReady());
          return;
        }
        emit(ClientOtpRequestFailure(failure));
      },
      (_) => emit(const ClientOtpRequestReady()),
    );
  }
}

/// Outcome of a [ClientOtpRequestCubit.request] call.
sealed class ClientOtpRequestState extends Equatable {
  /// Creates a [ClientOtpRequestState].
  const ClientOtpRequestState();

  @override
  List<Object?> get props => [];
}

/// Nothing dispatched yet.
class ClientOtpRequestInitial extends ClientOtpRequestState {
  /// Creates a [ClientOtpRequestInitial].
  const ClientOtpRequestInitial();
}

/// A dispatch is in flight.
class ClientOtpRequestInProgress extends ClientOtpRequestState {
  /// Creates a [ClientOtpRequestInProgress].
  const ClientOtpRequestInProgress();
}

/// A code is live — navigate to the shared OTP screen.
class ClientOtpRequestReady extends ClientOtpRequestState {
  /// Creates a [ClientOtpRequestReady].
  const ClientOtpRequestReady();
}

/// Dispatch failed for a reason the user must see; do not navigate.
class ClientOtpRequestFailure extends ClientOtpRequestState {
  /// Creates a [ClientOtpRequestFailure].
  const ClientOtpRequestFailure(this.failure);

  /// The dispatch failure to surface.
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
