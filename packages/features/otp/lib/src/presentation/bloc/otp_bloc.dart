import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:network/network.dart';
import 'package:otp/src/domain/enums/otp_purpose.dart';
import 'package:otp/src/domain/usecases/otp_params.dart';
import 'package:otp/src/domain/usecases/resend_otp_usecase.dart';
import 'package:otp/src/domain/usecases/validate_otp_usecase.dart';

part 'otp_event.dart';
part 'otp_state.dart';

class OtpBloc extends Bloc<OtpEvent, OtpState> {
  OtpBloc({
    required ValidateOtpUseCase validateOtpUseCase,
    required ResendOtpUseCase resendOtpUseCase,
    required SessionManager sessionManager,
    required AuthStatusNotifier authStatusNotifier,
  })  : _validateOtpUseCase = validateOtpUseCase,
        _resendOtpUseCase = resendOtpUseCase,
        _sessionManager = sessionManager,
        _authStatusNotifier = authStatusNotifier,
        super(const OtpInitialState()) {
    on<OtpValidateEvent>(_validate);
    on<OtpResendEvent>(_resend);
  }

  final ValidateOtpUseCase _validateOtpUseCase;
  final ResendOtpUseCase _resendOtpUseCase;
  final SessionManager _sessionManager;
  final AuthStatusNotifier _authStatusNotifier;

  Future<void> _validate(OtpValidateEvent event, Emitter<OtpState> emit) async {
    emit(const OtpValidateLoadingState());

    final result = await _validateOtpUseCase
        .call(
          ValidateOtpParams(
            identifier: event.identifier,
            otp: event.otp,
            purpose: event.purpose,
          ),
        )
        .run();

    await result.fold(
      (failure) async => emit(OtpValidateFailureState(failure)),
      (response) async {
        _authStatusNotifier.update(
          AuthStatus.authenticated,
          isProfileCompleted: response.user.isProfileCompleted,
        );
        await _sessionManager.startSession(
          accessToken: response.accessToken,
          refreshToken: response.refreshToken,
        );
        emit(
          OtpValidateSuccessState(
            response.user,
            'otp.account_created_success',
          ),
        );
      },
    );
  }

  Future<void> _resend(OtpResendEvent event, Emitter<OtpState> emit) async {
    emit(const OtpResendLoadingState());

    final result = await _resendOtpUseCase
        .call(
          ResendOtpParams(
            identifier: event.identifier,
            purpose: event.purpose,
          ),
        )
        .run();

    result.fold(
      (failure) => emit(OtpResendFailureState(failure)),
      (_) => emit(const OtpResendSuccessState()),
    );
  }
}
