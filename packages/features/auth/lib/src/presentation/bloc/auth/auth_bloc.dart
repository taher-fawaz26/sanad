import 'dart:async';

import 'package:auth/src/auth/auth_status.dart';
import 'package:auth/src/auth/auth_status_notifier.dart';
import 'package:auth/src/domain/entities/email_auth_result.dart';
import 'package:auth/src/domain/entities/user_entity.dart';
import 'package:auth/src/domain/usecases/check_signin_status_usecase.dart';
import 'package:auth/src/domain/usecases/delete_account_usecase.dart';
import 'package:auth/src/domain/usecases/logout_usecase.dart';
import 'package:auth/src/domain/usecases/request_email_otp_usecase.dart';
import 'package:auth/src/domain/usecases/usecase_params.dart';
import 'package:auth/src/domain/usecases/verify_email_otp_usecase.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:network/network.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required RequestEmailOtpUseCase requestOtpUseCase,
    required VerifyEmailOtpUseCase verifyOtpUseCase,
    required AuthLogoutUseCase logoutUseCase,
    required DeleteAccountUseCase deleteAccountUseCase,
    required SessionManager sessionManager,
    required AuthCheckSignInStatusUseCase checkSignInStatusUseCase,
    required AuthStatusNotifier authStatusNotifier,
  })  : _requestOtpUseCase = requestOtpUseCase,
        _verifyOtpUseCase = verifyOtpUseCase,
        _logoutUseCase = logoutUseCase,
        _deleteAccountUseCase = deleteAccountUseCase,
        _sessionManager = sessionManager,
        _checkSignInStatusUseCase = checkSignInStatusUseCase,
        _authStatusNotifier = authStatusNotifier,
        super(const AuthInitialState()) {
    on<AuthRequestOtpEvent>(_requestOtp);
    on<AuthVerifyOtpEvent>(_verifyOtp);
    on<AuthLogoutEvent>(_logout);
    on<AuthDeleteAccountEvent>(_deleteAccount);
    on<AuthCheckSignInStatusEvent>(_checkSignInStatus);
  }

  final RequestEmailOtpUseCase _requestOtpUseCase;
  final VerifyEmailOtpUseCase _verifyOtpUseCase;
  final AuthLogoutUseCase _logoutUseCase;
  final DeleteAccountUseCase _deleteAccountUseCase;
  final SessionManager _sessionManager;
  final AuthCheckSignInStatusUseCase _checkSignInStatusUseCase;
  final AuthStatusNotifier _authStatusNotifier;

  Future<void> _requestOtp(
    AuthRequestOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthOtpRequestLoadingState());

    final result = await _requestOtpUseCase
        .call(RequestEmailOtpParams(email: event.email))
        .run();

    result.match(
      (failure) => emit(AuthOtpRequestFailureState(failure)),
      (_) => emit(AuthOtpSentState(event.email)),
    );
  }

  Future<void> _verifyOtp(
    AuthVerifyOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthOtpVerifyLoadingState());

    final result = await _verifyOtpUseCase
        .call(VerifyEmailOtpParams(email: event.email, otp: event.otp))
        .run();

    await result.match(
      (failure) async => emit(AuthOtpVerifyFailureState(failure)),
      (outcome) async {
        switch (outcome) {
          case AuthenticatedResult(
              :final accessToken,
              :final refreshToken,
              :final user,
            ):
            await _sessionManager.startSession(
              accessToken: accessToken,
              refreshToken: refreshToken,
            );
            _authStatusNotifier.update(
              AuthStatus.authenticated,
              isProfileCompleted: user.isProfileCompleted,
            );
            emit(AuthAuthenticatedState(user));
          case OnboardingResult(:final email, :final onboardingToken):
            emit(
              AuthOnboardingRequiredState(
                email: email,
                onboardingToken: onboardingToken,
              ),
            );
        }
      },
    );
  }

  Future<void> _logout(AuthLogoutEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLogoutLoadingState());
    final result = await _logoutUseCase.call(const NoParams()).run();
    // Local session is cleared regardless of server outcome — the user
    // asked to log out and must be logged out on this device.
    await _sessionManager.logout();
    _authStatusNotifier.update(AuthStatus.unauthenticated);
    await result.match(
      (failure) async => emit(AuthLogoutFailureState(failure)),
      (_) async => emit(const AuthLogoutSuccessState('auth.logout_success')),
    );
  }

  Future<void> _deleteAccount(
    AuthDeleteAccountEvent event,
    Emitter<AuthState> emit,
  ) async {
    final previousUser = _userFromState(state);
    if (previousUser == null) {
      emit(
        const AuthDeleteAccountFailureState(
          UnknownFailure(message: 'auth.delete_account_no_user'),
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
          AuthDeleteAccountFailureState(failure, user: previousUser),
        );
      },
      (_) async {
        await _sessionManager.logout();
        emit(const AuthLogoutSuccessState('auth.account_deleted_success'));
        _authStatusNotifier.update(AuthStatus.unauthenticated);
      },
    );
  }

  Future<void> _checkSignInStatus(
    AuthCheckSignInStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthCheckSignInStatusLoadingState());

    final result =
        await _checkSignInStatusUseCase.call(const NoParams()).run();

    await result.match(
      (l) async {
        emit(
          const AuthCheckSignInStatusFailureState(
            'auth.session_unauthenticated',
          ),
        );
        _authStatusNotifier.update(AuthStatus.unauthenticated);
      },
      (user) async {
        if (user == null) {
          emit(
            const AuthCheckSignInStatusFailureState(
              'auth.session_unauthenticated',
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

  static UserEntity? _userFromState(AuthState state) => switch (state) {
        AuthAuthenticatedState(:final user) => user,
        AuthCheckSignInStatusSuccessState(:final user) => user,
        AuthDeleteAccountLoadingState(:final user) => user,
        AuthDeleteAccountFailureState(:final user) => user,
        _ => null,
      };
}
