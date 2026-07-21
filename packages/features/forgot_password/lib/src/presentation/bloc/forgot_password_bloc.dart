import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forgot_password/src/domain/usecases/forgot_password_params.dart';
import 'package:forgot_password/src/domain/usecases/request_forgot_password_usecase.dart';
import 'package:forgot_password/src/domain/usecases/reset_password_usecase.dart';
import 'package:forgot_password/src/domain/usecases/verify_forgot_password_otp_usecase.dart';

part 'forgot_password_event.dart';
part 'forgot_password_state.dart';

class ForgotPasswordBloc
    extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  ForgotPasswordBloc({
    required RequestForgotPasswordUseCase requestForgotPasswordUseCase,
    required VerifyForgotPasswordOtpUseCase verifyForgotPasswordOtpUseCase,
    required ResetPasswordUseCase resetPasswordUseCase,
  })  : _requestForgotPasswordUseCase = requestForgotPasswordUseCase,
        _verifyForgotPasswordOtpUseCase = verifyForgotPasswordOtpUseCase,
        _resetPasswordUseCase = resetPasswordUseCase,
        super(const ForgotPasswordInitialState()) {
    on<ForgotPasswordRequestEvent>(_request);
    on<ForgotPasswordVerifyOtpEvent>(_verifyOtp);
    on<ForgotPasswordResendOtpEvent>(_resendOtp);
    on<ForgotPasswordResetEvent>(_reset);
  }

  final RequestForgotPasswordUseCase _requestForgotPasswordUseCase;
  final VerifyForgotPasswordOtpUseCase _verifyForgotPasswordOtpUseCase;
  final ResetPasswordUseCase _resetPasswordUseCase;

  Future<void> _request(
    ForgotPasswordRequestEvent event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    emit(const ForgotPasswordRequestLoadingState());
    final result = await _requestForgotPasswordUseCase
        .call(
          ForgotPasswordRequestParams(identifier: event.identifier.trim()),
        )
        .run();
    result.fold(
      (failure) => emit(ForgotPasswordRequestFailureState(failure)),
      (_) => emit(const ForgotPasswordOtpSentState()),
    );
  }

  Future<void> _verifyOtp(
    ForgotPasswordVerifyOtpEvent event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    emit(const ForgotPasswordOtpVerifyLoadingState());
    final result = await _verifyForgotPasswordOtpUseCase
        .call(
          VerifyForgotPasswordOtpParams(
            identifier: event.identifier,
            otp: event.otp,
          ),
        )
        .run();
    result.fold(
      (failure) => emit(ForgotPasswordOtpFailureState(failure)),
      (_) => emit(const ForgotPasswordOtpVerifiedState()),
    );
  }

  Future<void> _resendOtp(
    ForgotPasswordResendOtpEvent event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    emit(const ForgotPasswordOtpResendLoadingState());
    final result = await _requestForgotPasswordUseCase
        .call(
          ForgotPasswordRequestParams(identifier: event.identifier.trim()),
        )
        .run();
    result.fold(
      (failure) => emit(ForgotPasswordOtpFailureState(failure)),
      (_) => emit(const ForgotPasswordOtpReadyState()),
    );
  }

  Future<void> _reset(
    ForgotPasswordResetEvent event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    emit(const ForgotPasswordResetLoadingState());
    final result = await _resetPasswordUseCase
        .call(
          ResetPasswordParams(
            identifier: event.identifier,
            password: event.password,
          ),
        )
        .run();
    result.fold(
      (failure) => emit(ForgotPasswordResetFailureState(failure)),
      (_) => emit(const ForgotPasswordResetSuccessState()),
    );
  }
}
