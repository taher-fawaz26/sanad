import 'dart:async';

import 'package:auth/src/auth/auth_status.dart';
import 'package:auth/src/auth/auth_status_notifier.dart';
import 'package:auth/src/domain/entities/auth_response_entity.dart';
import 'package:auth/src/domain/entities/login_result_entity.dart';
import 'package:auth/src/domain/entities/resend_info_entity.dart';
import 'package:auth/src/domain/entities/user_entity.dart';
import 'package:auth/src/domain/enums/auth_account_status.dart';
import 'package:auth/src/domain/enums/auth_flow_intent.dart';
import 'package:auth/src/domain/usecases/check_signin_status_usecase.dart';
import 'package:auth/src/domain/usecases/delete_account_usecase.dart';
import 'package:auth/src/domain/usecases/get_current_user_usecase.dart';
import 'package:auth/src/domain/usecases/get_resend_info_usecase.dart';
import 'package:auth/src/domain/usecases/logout_usecase.dart';
import 'package:auth/src/domain/usecases/request_login_otp_usecase.dart';
import 'package:auth/src/domain/usecases/request_signup_otp_usecase.dart';
import 'package:auth/src/domain/usecases/resend_otp_usecase.dart';
import 'package:auth/src/domain/usecases/social_login_usecase.dart';
import 'package:auth/src/domain/usecases/social_signup_usecase.dart';
import 'package:auth/src/domain/usecases/usecase_params.dart';
import 'package:auth/src/session/complete_active_login.dart';
import 'package:auth/src/session/session_manager.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required RequestSignupOtpUseCase requestSignupOtpUseCase,
    required RequestLoginOtpUseCase requestLoginOtpUseCase,
    required ResendOtpUseCase resendOtpUseCase,
    required GetResendInfoUseCase getResendInfoUseCase,
    required AuthLogoutUseCase logoutUseCase,
    required DeleteAccountUseCase deleteAccountUseCase,
    required SessionManager sessionManager,
    required AuthCheckSignInStatusUseCase checkSignInStatusUseCase,
    required AuthStatusNotifier authStatusNotifier,
    required SocialSignupUseCase socialSignupUseCase,
    required SocialLoginUseCase socialLoginUseCase,
    required GetCurrentUserUseCase getCurrentUserUseCase,
  }) : _requestSignupOtpUseCase = requestSignupOtpUseCase,
       _requestLoginOtpUseCase = requestLoginOtpUseCase,
       _resendOtpUseCase = resendOtpUseCase,
       _getResendInfoUseCase = getResendInfoUseCase,
       _logoutUseCase = logoutUseCase,
       _deleteAccountUseCase = deleteAccountUseCase,
       _sessionManager = sessionManager,
       _checkSignInStatusUseCase = checkSignInStatusUseCase,
       _authStatusNotifier = authStatusNotifier,
       _socialSignupUseCase = socialSignupUseCase,
       _socialLoginUseCase = socialLoginUseCase,
       _getCurrentUserUseCase = getCurrentUserUseCase,
       super(const AuthInitialState()) {
    on<AuthRequestOtpEvent>(_requestOtp);
    on<AuthResendOtpEvent>(_resendOtp);
    on<AuthResendInfoRequestedEvent>(_resendInfo);
    on<AuthLogoutEvent>(_logout);
    on<AuthDeleteAccountEvent>(_deleteAccount);
    on<AuthCheckSignInStatusEvent>(_checkSignInStatus);
    on<AuthGoogleSignInEvent>(_signInWithGoogle);
  }

  final RequestSignupOtpUseCase _requestSignupOtpUseCase;
  final RequestLoginOtpUseCase _requestLoginOtpUseCase;
  final ResendOtpUseCase _resendOtpUseCase;
  final GetResendInfoUseCase _getResendInfoUseCase;
  final AuthLogoutUseCase _logoutUseCase;
  final DeleteAccountUseCase _deleteAccountUseCase;
  final SessionManager _sessionManager;
  final AuthCheckSignInStatusUseCase _checkSignInStatusUseCase;
  final AuthStatusNotifier _authStatusNotifier;
  final SocialSignupUseCase _socialSignupUseCase;
  final SocialLoginUseCase _socialLoginUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;

  Future<void> _requestOtp(
    AuthRequestOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthOtpRequestLoadingState());
    final params = RequestEmailOtpParams(email: event.email);
    final result = await switch (event.intent) {
      AuthFlowIntent.signIn => _requestLoginOtpUseCase(params),
      AuthFlowIntent.createAccount => _requestSignupOtpUseCase(params),
    }.run();

    result.match(
      (failure) => emit(AuthOtpRequestFailureState(failure)),
      (_) => emit(AuthOtpSentState(email: event.email, intent: event.intent)),
    );
  }

  Future<void> _resendOtp(
    AuthResendOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _resendOtpUseCase
        .call(RequestEmailOtpParams(email: event.email))
        .run();

    result.match(
      (failure) => emit(AuthOtpRequestFailureState(failure)),
      // The resend confirmation reuses AuthOtpSentState purely as a "resent"
      // signal; intent is irrelevant here since resend-otp isn't split.
      (_) => emit(
        AuthOtpSentState(email: event.email, intent: AuthFlowIntent.signIn),
      ),
    );
  }

  Future<void> _resendInfo(
    AuthResendInfoRequestedEvent event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _getResendInfoUseCase
        .call(RequestEmailOtpParams(email: event.email))
        .run();

    result.match(
      (failure) => emit(AuthResendInfoFailureState(failure)),
      (info) => emit(AuthResendInfoState(info)),
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
        // GET /me re-hydration on resume (decision, plan §19): the
        // persisted snapshot may be stale (role/permission change, or a
        // pre-rename `companyProvider` value). Best-effort — a failure here
        // (e.g. a transient 401 while a silent refresh is in flight) must
        // not block an otherwise-valid local session from loading; the
        // session simply keeps its last-known identity until the next
        // successful /me call.
        final identityResult = await _getCurrentUserUseCase(
          const NoParams(),
        ).run();
        await identityResult.match(
          (_) async {},
          (identity) async => _sessionManager.hydrateIdentity(identity),
        );
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

    switch (event.intent) {
      case AuthFlowIntent.createAccount:
        final result = await _socialSignupUseCase(const NoParams()).run();
        await result.match(
          (failure) async => emit(AuthGoogleSignInFailureState(failure)),
          (response) async => _handleAuthResponse(response, emit),
        );
      case AuthFlowIntent.signIn:
        final result = await _socialLoginUseCase(const NoParams()).run();
        await result.match(
          (failure) async => emit(AuthGoogleSignInFailureState(failure)),
          (loginResult) async => _handleLoginResult(loginResult, emit),
        );
    }
  }

  Future<void> _handleAuthResponse(
    AuthResponseEntity response,
    Emitter<AuthState> emit,
  ) async {
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
  }

  Future<void> _handleLoginResult(
    LoginResult result,
    Emitter<AuthState> emit,
  ) async {
    switch (result.status) {
      case AuthAccountStatus.active:
        final accessToken = result.accessToken;
        final refreshToken = result.refreshToken;
        if (accessToken == null || refreshToken == null) {
          emit(
            const AuthGoogleSignInFailureState(
              UnknownFailure(message: 'auth.malformed_login_response'),
            ),
          );
          return;
        }
        final userResult = await completeActiveLogin(
          accessToken: accessToken,
          refreshToken: refreshToken,
          getCurrentUser: _getCurrentUserUseCase,
          sessionManager: _sessionManager,
        ).run();
        userResult.match(
          (failure) => emit(AuthGoogleSignInFailureState(failure)),
          (user) => emit(AuthAuthenticatedState(user)),
        );
      case AuthAccountStatus.incomplete:
        // `accessToken` here IS the onboarding token; refreshToken is null.
        final onboardingToken = result.accessToken;
        if (onboardingToken == null) {
          emit(
            const AuthGoogleSignInFailureState(
              UnknownFailure(message: 'auth.malformed_login_response'),
            ),
          );
          return;
        }
        // NOTE: unlike the OTP path (EmailOtpPage, which already knows the
        // email the user typed), `LoginResponseDto` carries no email — the
        // social/login wire shape is tokens+status only. This is a known
        // gap tied to the plan's open question on social-intent UX (§31 Q2);
        // the registration flow re-collects the email during onboarding.
        emit(
          AuthOnboardingRequiredState(
            email: '',
            onboardingToken: onboardingToken,
          ),
        );
      case AuthAccountStatus.suspended:
        emit(const AuthSuspendedState());
    }
  }

  static UserEntity? _userFromState(AuthState state) => switch (state) {
    AuthAuthenticatedState(:final user) => user,
    AuthCheckSignInStatusSuccessState(:final user) => user,
    AuthDeleteAccountLoadingState(:final user) => user,
    AuthDeleteAccountFailureState(:final user) => user,
    _ => null,
  };
}
