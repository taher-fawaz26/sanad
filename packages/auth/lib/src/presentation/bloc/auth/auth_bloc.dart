import 'dart:async';

import 'package:auth/src/auth/auth_status.dart';
import 'package:auth/src/auth/auth_status_notifier.dart';
import 'package:auth/src/domain/entities/user_entity.dart';
import 'package:auth/src/domain/enums/user_type.dart';
import 'package:auth/src/domain/usecases/check_signin_status_usecase.dart';
import 'package:auth/src/domain/usecases/delete_account_usecase.dart';
import 'package:auth/src/domain/usecases/login_usecase.dart';
import 'package:auth/src/domain/usecases/logout_usecase.dart';
import 'package:auth/src/domain/usecases/register_usecase.dart';
import 'package:auth/src/domain/usecases/request_forgot_password_usecase.dart';
import 'package:auth/src/domain/usecases/resend_otp_usecase.dart';
import 'package:auth/src/domain/usecases/reset_password_usecase.dart';
import 'package:auth/src/domain/usecases/usecase_params.dart';
import 'package:auth/src/domain/usecases/validate_otp_usecase.dart';
import 'package:auth/src/domain/usecases/verify_forgot_password_otp_usecase.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:network/network.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required AuthLoginUseCase loginUseCase,
    required AuthLogoutUseCase logoutUseCase,
    required DeleteAccountUseCase deleteAccountUseCase,
    required AuthRegisterUseCase registerUseCase,
    required AuthValidateOtpUseCase validateOtpUseCase,
    required RequestForgotPasswordUseCase requestForgotPasswordUseCase,
    required VerifyForgotPasswordOtpUseCase verifyForgotPasswordOtpUseCase,
    required ResetPasswordUseCase resetPasswordUseCase,
    required ResendOtpUseCase resendOtpUseCase,
    required SessionManager sessionManager,
    required AuthCheckSignInStatusUseCase checkSignInStatusUseCase,
    required AuthStatusNotifier authStatusNotifier,
  })  : _loginUseCase = loginUseCase,
        _logoutUseCase = logoutUseCase,
        _deleteAccountUseCase = deleteAccountUseCase,
        _registerUseCase = registerUseCase,
        _validateOtpUseCase = validateOtpUseCase,
        _requestForgotPasswordUseCase = requestForgotPasswordUseCase,
        _verifyForgotPasswordOtpUseCase = verifyForgotPasswordOtpUseCase,
        _resetPasswordUseCase = resetPasswordUseCase,
        _resendOtpUseCase = resendOtpUseCase,
        _sessionManager = sessionManager,
        _checkSignInStatusUseCase = checkSignInStatusUseCase,
        _authStatusNotifier = authStatusNotifier,
        super(const AuthInitialState()) {
    on<AuthLoginEvent>(_login);
    on<AuthLogoutEvent>(_logout);
    on<AuthDeleteAccountEvent>(_deleteAccount);
    on<AuthRegisterEvent>(_register);
    on<AuthCheckSignInStatusEvent>(_checkSignInStatus);
    on<AuthValidateOtpEvent>(_validateOtp);
    on<AuthForgotPasswordRequestEvent>(_forgotPasswordRequest);
    on<AuthVerifyForgotPasswordOtpEvent>(_verifyForgotPasswordOtp);
    on<AuthResendForgotPasswordOtpEvent>(_resendForgotPasswordOtp);
    on<AuthResetPasswordEvent>(_resetPassword);
    on<AuthResendOtpEvent>(_resendOtp);
  }

  final AuthLoginUseCase _loginUseCase;
  final AuthLogoutUseCase _logoutUseCase;
  final DeleteAccountUseCase _deleteAccountUseCase;
  final AuthRegisterUseCase _registerUseCase;
  final AuthValidateOtpUseCase _validateOtpUseCase;
  final RequestForgotPasswordUseCase _requestForgotPasswordUseCase;
  final VerifyForgotPasswordOtpUseCase _verifyForgotPasswordOtpUseCase;
  final ResetPasswordUseCase _resetPasswordUseCase;
  final ResendOtpUseCase _resendOtpUseCase;
  final SessionManager _sessionManager;
  final AuthCheckSignInStatusUseCase _checkSignInStatusUseCase;
  final AuthStatusNotifier _authStatusNotifier;

  Future<void> _login(AuthLoginEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoginLoadingState());

    final result = await _loginUseCase
        .call(
          LoginParams(identifier: event.identifier, password: event.password),
        )
        .run();

    await result.match(
      (failure) async {
        if (failure is UnverifiedUserFailure) {
          emit(const AuthLoginUnverifiedState());
          return;
        }
        emit(AuthLoginFailureState(failure.message, code: failure.code));
      },
      (r) async {
        _authStatusNotifier.update(
          AuthStatus.authenticated,
          isProfileCompleted: r.user.isProfileCompleted,
        );
        await _sessionManager.startSession(
          accessToken: r.accessToken,
          refreshToken: r.refreshToken,
        );
        emit(AuthLoginSuccessState(r.user));
      },
    );
  }

  Future<void> _logout(AuthLogoutEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLogoutLoadingState());
    await _logoutUseCase.call(const NoParams()).run();
    await _sessionManager.logout();
    emit(const AuthLogoutSuccessState('auth_messages.logout_success'));
    _authStatusNotifier.update(AuthStatus.unauthenticated);
  }

  Future<void> _deleteAccount(
    AuthDeleteAccountEvent event,
    Emitter<AuthState> emit,
  ) async {
    final previousUser = _userFromState(state);
    if (previousUser == null) {
      emit(
        const AuthDeleteAccountFailureState(
          'auth_messages.delete_account_no_user',
          user: null,
        ),
      );
      return;
    }

    emit(AuthDeleteAccountLoadingState(previousUser));

    final result = await _deleteAccountUseCase
        .call(DeleteAccountParams(userSub: event.userSub))
        .run();

    await result.match(
      (failure) async {
        emit(
          AuthDeleteAccountFailureState(failure.message, user: previousUser),
        );
      },
      (_) async {
        await _sessionManager.logout();
        emit(
          const AuthLogoutSuccessState(
            'auth_messages.account_deleted_success',
          ),
        );
        _authStatusNotifier.update(AuthStatus.unauthenticated);
      },
    );
  }

  Future<void> _register(
    AuthRegisterEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthRegisterLoadingState());

    final result = await _registerUseCase
        .call(
          RegisterParams(
            identifier: event.identifier,
            password: event.password,
            type: event.type,
          ),
        )
        .run();

    result.fold(
      (l) => emit(AuthRegisterFailureState(l.message)),
      (_) => emit(
        const AuthRegisterSuccessState('auth_messages.register_success'),
      ),
    );
  }

  Future<void> _checkSignInStatus(
    AuthCheckSignInStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthCheckSignInStatusLoadingState());

    // TokenManager is already initialized with persisted tokens by DI.
    // The use case checks the in-memory token and loads UserEntity from cache.
    final result = await _checkSignInStatusUseCase
        .call(const NoParams())
        .run();

    result.fold(
      (l) {
        emit(
          const AuthCheckSignInStatusFailureState(
            'auth_messages.session_unauthenticated',
          ),
        );
        _authStatusNotifier.update(AuthStatus.unauthenticated);
      },
      (user) {
        if (user == null) {
          emit(
            const AuthCheckSignInStatusFailureState(
              'auth_messages.session_unauthenticated',
            ),
          );
          _authStatusNotifier.update(AuthStatus.unauthenticated);
          return;
        }
        emit(AuthCheckSignInStatusSuccessState(user));
        _authStatusNotifier.update(
          AuthStatus.authenticated,
          isProfileCompleted: user.isProfileCompleted,
        );
      },
    );
  }

  Future<void> _validateOtp(
    AuthValidateOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthValidateOtpLoadingState());

    final result = await _validateOtpUseCase
        .call(ValidateOtpParams(identifier: event.identifier, otp: event.otp))
        .run();

    await result.fold(
      (l) async => emit(AuthValidateOtpFailureState(l.message)),
      (r) async {
        emit(
          AuthValidateOtpSuccessState(
            r.user,
            'auth_messages.account_created_success',
          ),
        );
        _authStatusNotifier.update(
          AuthStatus.authenticated,
          isProfileCompleted: r.user.isProfileCompleted,
        );
        await _sessionManager.startSession(
          accessToken: r.accessToken,
          refreshToken: r.refreshToken,
        );
      },
    );
  }

  Future<void> _forgotPasswordRequest(
    AuthForgotPasswordRequestEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthForgotPasswordRequestLoadingState());
    final result = await _requestForgotPasswordUseCase
        .call(ForgotPasswordRequestParams(identifier: event.identifier.trim()))
        .run();
    result.fold(
      (failure) =>
          emit(AuthForgotPasswordRequestFailureState(failure.message)),
      (_) => emit(const AuthForgotPasswordOtpSentState()),
    );
  }

  Future<void> _verifyForgotPasswordOtp(
    AuthVerifyForgotPasswordOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthForgotPasswordOtpVerifyLoadingState());
    final result = await _verifyForgotPasswordOtpUseCase
        .call(
          VerifyForgotPasswordOtpParams(
            identifier: event.identifier,
            otp: event.otp,
          ),
        )
        .run();
    result.fold(
      (failure) => emit(AuthForgotPasswordOtpFailureState(failure.message)),
      (_) => emit(const AuthForgotPasswordOtpVerifiedState()),
    );
  }

  Future<void> _resendForgotPasswordOtp(
    AuthResendForgotPasswordOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthForgotPasswordOtpResendLoadingState());
    final result = await _requestForgotPasswordUseCase
        .call(ForgotPasswordRequestParams(identifier: event.identifier.trim()))
        .run();
    result.fold(
      (failure) => emit(AuthForgotPasswordOtpFailureState(failure.message)),
      (_) => emit(const AuthForgotPasswordOtpReadyState()),
    );
  }

  Future<void> _resetPassword(
    AuthResetPasswordEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthResetPasswordLoadingState());
    final result = await _resetPasswordUseCase
        .call(
          ResetPasswordParams(
            identifier: event.identifier,
            password: event.password,
          ),
        )
        .run();
    result.fold(
      (failure) => emit(AuthResetPasswordFailureState(failure.message)),
      (_) => emit(const AuthResetPasswordSuccessState()),
    );
  }

  Future<void> _resendOtp(
    AuthResendOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthResendOtpLoadingState());
    final result = await _resendOtpUseCase
        .call(
          ResendOtpParams(
            identifier: event.identifier,
            purpose: event.purpose,
          ),
        )
        .run();
    result.fold(
      (failure) => emit(AuthResendOtpFailureState(failure.message)),
      (_) => emit(const AuthResendOtpSuccessState()),
    );
  }
}

UserEntity? _userFromState(AuthState state) => switch (state) {
      AuthLoginSuccessState(:final user) => user,
      AuthCheckSignInStatusSuccessState(:final user) => user,
      AuthValidateOtpSuccessState(:final user) => user,
      AuthDeleteAccountLoadingState(:final user) => user,
      AuthDeleteAccountFailureState(:final user) => user,
      _ => null,
    };
