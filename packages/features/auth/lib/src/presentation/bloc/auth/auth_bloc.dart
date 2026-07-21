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
import 'package:auth/src/domain/usecases/usecase_params.dart';
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
    required SessionManager sessionManager,
    required AuthCheckSignInStatusUseCase checkSignInStatusUseCase,
    required AuthStatusNotifier authStatusNotifier,
  })  : _loginUseCase = loginUseCase,
        _logoutUseCase = logoutUseCase,
        _deleteAccountUseCase = deleteAccountUseCase,
        _registerUseCase = registerUseCase,
        _sessionManager = sessionManager,
        _checkSignInStatusUseCase = checkSignInStatusUseCase,
        _authStatusNotifier = authStatusNotifier,
        super(const AuthInitialState()) {
    on<AuthLoginEvent>(_login);
    on<AuthLogoutEvent>(_logout);
    on<AuthDeleteAccountEvent>(_deleteAccount);
    on<AuthRegisterEvent>(_register);
    on<AuthCheckSignInStatusEvent>(_checkSignInStatus);
  }

  final AuthLoginUseCase _loginUseCase;
  final AuthLogoutUseCase _logoutUseCase;
  final DeleteAccountUseCase _deleteAccountUseCase;
  final AuthRegisterUseCase _registerUseCase;
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
        emit(AuthLoginFailureState(failure));
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

    await result.match(
      (l) async => emit(AuthRegisterFailureState(l)),
      (_) async =>
          emit(const AuthRegisterSuccessState('auth.register_success')),
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
    AuthLoginSuccessState(:final user) => user,
    AuthCheckSignInStatusSuccessState(:final user) => user,
    AuthDeleteAccountLoadingState(:final user) => user,
    AuthDeleteAccountFailureState(:final user) => user,
    _ => null,
  };
}
