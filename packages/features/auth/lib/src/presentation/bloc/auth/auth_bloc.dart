import 'dart:async';

import 'package:auth/src/auth/auth_status.dart';
import 'package:auth/src/auth/auth_status_notifier.dart';
import 'package:auth/src/domain/entities/auth_response_entity.dart';
import 'package:auth/src/domain/entities/user_entity.dart';
import 'package:auth/src/domain/usecases/check_signin_status_usecase.dart';
import 'package:auth/src/domain/usecases/delete_account_usecase.dart';
import 'package:auth/src/domain/usecases/logout_usecase.dart';
import 'package:auth/src/domain/usecases/request_email_otp_usecase.dart';
import 'package:auth/src/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:auth/src/domain/usecases/usecase_params.dart';
import 'package:auth/src/domain/usecases/validate_email_usecase.dart';
import 'package:auth/src/session/session_manager.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required RequestEmailOtpUseCase requestOtpUseCase,
    required AuthLogoutUseCase logoutUseCase,
    required DeleteAccountUseCase deleteAccountUseCase,
    required SessionManager sessionManager,
    required AuthCheckSignInStatusUseCase checkSignInStatusUseCase,
    required AuthStatusNotifier authStatusNotifier,
    required SignInWithGoogleUseCase signInWithGoogleUseCase,
    required ValidateEmailUseCase validateEmailUseCase,
  }) : _requestOtpUseCase = requestOtpUseCase,
       _logoutUseCase = logoutUseCase,
       _deleteAccountUseCase = deleteAccountUseCase,
       _sessionManager = sessionManager,
       _checkSignInStatusUseCase = checkSignInStatusUseCase,
       _authStatusNotifier = authStatusNotifier,
       _signInWithGoogleUseCase = signInWithGoogleUseCase,
       _validateEmailUseCase = validateEmailUseCase,
       super(const AuthInitialState()) {
    on<AuthRequestOtpEvent>(_requestOtp);
    on<AuthLogoutEvent>(_logout);
    on<AuthDeleteAccountEvent>(_deleteAccount);
    on<AuthCheckSignInStatusEvent>(_checkSignInStatus);
    on<AuthGoogleSignInEvent>(_signInWithGoogle);
    on<AuthValidateEmailEvent>(_validateEmail);
  }

  final RequestEmailOtpUseCase _requestOtpUseCase;
  final AuthLogoutUseCase _logoutUseCase;
  final DeleteAccountUseCase _deleteAccountUseCase;
  final SessionManager _sessionManager;
  final AuthCheckSignInStatusUseCase _checkSignInStatusUseCase;
  final AuthStatusNotifier _authStatusNotifier;
  final SignInWithGoogleUseCase _signInWithGoogleUseCase;
  final ValidateEmailUseCase _validateEmailUseCase;

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

  Future<void> _validateEmail(
    AuthValidateEmailEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthValidateEmailLoadingState());

    final validateResult = await _validateEmailUseCase
        .call(ValidateEmailParams(email: event.email))
        .run();
    validateResult.match(
      (failure) => emit(AuthValidateEmailFailureState(failure)),
      (emailAvailable) {
        final emailExists = !emailAvailable;
        if (event.isLogin && emailExists) {
          emit(
            AuthValidateEmailSuccessState(
              emailExists,
            ),
          );

          return;
        } else if (event.isLogin && !emailExists) {
          emit(
            const AuthValidateEmailFailureState(
              EmailNotValidFailure(message: 'errors.email_not_found'),
            ),
          );
          return;
        } else if (!event.isLogin && emailExists) {
          emit(
            const AuthValidateEmailFailureState(
              EmailNotValidFailure(message: 'errors.email_not_valid'),
            ),
          );
          return;
        } else {
          emit(AuthValidateEmailSuccessState(emailExists));
          return;
        }
      },
    );
  }

  Future<void> _logout(AuthLogoutEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLogoutLoadingState());
    final result = await _logoutUseCase.call(const NoParams()).run();
    // Local session is cleared regardless of server outcome — the user
    // asked to log out and must be logged out on this device.
    // SessionManager.clear also flips AuthStatusNotifier to unauthenticated.
    await _sessionManager.clear();
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
        await _sessionManager.clear();
        emit(const AuthLogoutSuccessState('auth.account_deleted_success'));
      },
    );
  }

  Future<void> _checkSignInStatus(
    AuthCheckSignInStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthCheckSignInStatusLoadingState());

    final result = await _checkSignInStatusUseCase.call(const NoParams()).run();

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
        // The session was restored from Hive by SessionManager.restore() in
        // AuthModule.initialize(), which already flipped AuthStatusNotifier
        // to authenticated with the correct isProfileCompleted flag. Re-emit
        // here would be redundant, so the bloc only owns the state stream.
      },
    );
  }

  Future<void> _signInWithGoogle(
    AuthGoogleSignInEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthGoogleSignInLoadingState());

    final result = await _signInWithGoogleUseCase.call(const NoParams()).run();

    await result.match(
      (failure) async => emit(AuthGoogleSignInFailureState(failure)),
      (response) async {
        switch (response) {
          case final AuthSessionEntity session:
            // Single call persists tokens + Hive session + flips the
            // AuthStatusNotifier to authenticated.
            await _sessionManager.save(session);
            emit(AuthAuthenticatedState(session.user));
          case OnboardingAuthEntity(:final onboardingToken, :final user):
            emit(
              AuthOnboardingRequiredState(
                email: user.email,
                onboardingToken: onboardingToken,
              ),
            );
        }
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
