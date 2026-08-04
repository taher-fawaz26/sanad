// ignore_for_file: prefer_const_constructors // blocTest act: lambdas prevent Dart from inferring const at call-sites

import 'package:auth/src/auth/auth_status.dart';
import 'package:auth/src/auth/auth_status_notifier.dart';
import 'package:auth/src/domain/entities/user_entity.dart';
import 'package:auth/src/domain/enums/user_type.dart';
import 'package:auth/src/domain/usecases/check_signin_status_usecase.dart';
import 'package:auth/src/domain/usecases/delete_account_usecase.dart';
import 'package:auth/src/domain/usecases/logout_usecase.dart';
import 'package:auth/src/domain/usecases/request_email_otp_usecase.dart';
import 'package:auth/src/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:auth/src/domain/usecases/usecase_params.dart';
import 'package:auth/src/domain/usecases/validate_email_usecase.dart';
import 'package:auth/src/presentation/bloc/auth/auth_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:network/network.dart';

// ── Mocks ──────────────────────────────────────────────────────────────────

class _MockRequestOtpUseCase extends Mock implements RequestEmailOtpUseCase {}

class _MockValidateEmailUseCase extends Mock implements ValidateEmailUseCase {}

class _MockLogoutUseCase extends Mock implements AuthLogoutUseCase {}

class _MockDeleteAccountUseCase extends Mock implements DeleteAccountUseCase {}

class _MockSessionManager extends Mock implements SessionManager {}

class _MockCheckSignInStatusUseCase extends Mock
    implements AuthCheckSignInStatusUseCase {}

class _MockSignInWithGoogleUseCase extends Mock
    implements SignInWithGoogleUseCase {}

// ── Fixture data ───────────────────────────────────────────────────────────

const _tEmail = 'user@example.com';

const _tUser = UserEntity(
  id: 'sub-123',
  email: _tEmail,
  isVerified: true,
  isActive: true,
  type: UserType.client,
);

const _tFailure = ServerFailure(message: 'server_error');

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  late _MockRequestOtpUseCase requestOtpUseCase;
  late _MockLogoutUseCase logoutUseCase;
  late _MockDeleteAccountUseCase deleteAccountUseCase;
  late _MockSessionManager sessionManager;
  late _MockCheckSignInStatusUseCase checkSignInStatusUseCase;
  late _MockSignInWithGoogleUseCase signInWithGoogleUseCase;
  late AuthStatusNotifier authStatusNotifier;
  late _MockValidateEmailUseCase validateEmailUseCase;
  AuthBloc buildBloc() => AuthBloc(
    requestOtpUseCase: requestOtpUseCase,
    logoutUseCase: logoutUseCase,
    deleteAccountUseCase: deleteAccountUseCase,
    sessionManager: sessionManager,
    checkSignInStatusUseCase: checkSignInStatusUseCase,
    authStatusNotifier: authStatusNotifier,
    signInWithGoogleUseCase: signInWithGoogleUseCase,
    validateEmailUseCase: validateEmailUseCase,
  );

  setUpAll(() {
    registerFallbackValue(const RequestEmailOtpParams(email: ''));
    registerFallbackValue(const ValidateEmailParams(email: ''));
    registerFallbackValue(const DeleteAccountParams(userSub: ''));
    registerFallbackValue(const NoParams());
  });

  setUp(() {
    requestOtpUseCase = _MockRequestOtpUseCase();
    logoutUseCase = _MockLogoutUseCase();
    deleteAccountUseCase = _MockDeleteAccountUseCase();
    sessionManager = _MockSessionManager();
    checkSignInStatusUseCase = _MockCheckSignInStatusUseCase();
    signInWithGoogleUseCase = _MockSignInWithGoogleUseCase();
    validateEmailUseCase = _MockValidateEmailUseCase();
    authStatusNotifier = AuthStatusNotifier();

    when(
      () => sessionManager.startSession(
        accessToken: any(named: 'accessToken'),
        refreshToken: any(named: 'refreshToken'),
      ),
    ).thenAnswer((_) async {});
    when(() => sessionManager.logout()).thenAnswer((_) async {});
  });

  group('AuthBloc', () {
    test('initial state is AuthInitialState', () {
      expect(buildBloc().state, isA<AuthInitialState>());
    });

    // ── Request OTP ────────────────────────────────────────────────────────

    group('AuthRequestOtpEvent', () {
      blocTest<AuthBloc, AuthState>(
        'emits [loading, sent] when the OTP request succeeds',
        build: () {
          when(
            () => requestOtpUseCase(any()),
          ).thenReturn(TaskEither<Failure, void>.right(null));
          return buildBloc();
        },
        act: (bloc) => bloc.add(const AuthRequestOtpEvent(_tEmail)),
        expect: () => [
          isA<AuthOtpRequestLoadingState>(),
          isA<AuthOtpSentState>().having((s) => s.email, 'email', _tEmail),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, failure] when the OTP request fails',
        build: () {
          when(
            () => requestOtpUseCase(any()),
          ).thenReturn(TaskEither.left(_tFailure));
          return buildBloc();
        },
        act: (bloc) => bloc.add(const AuthRequestOtpEvent(_tEmail)),
        expect: () => [
          isA<AuthOtpRequestLoadingState>(),
          isA<AuthOtpRequestFailureState>(),
        ],
      );
    });

    // ── Validate email ─────────────────────────────────────────────────────

    group('AuthValidateEmailEvent', () {
      blocTest<AuthBloc, AuthState>(
        'sign-in + email in use → success',
        build: () {
          when(
            () => validateEmailUseCase(any()),
          ).thenReturn(TaskEither.right(false));
          return buildBloc();
        },
        act: (bloc) => bloc.add(
          const AuthValidateEmailEvent(email: _tEmail, isLogin: true),
        ),
        expect: () => [
          isA<AuthValidateEmailLoadingState>(),
          isA<AuthValidateEmailSuccessState>(),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'sign-in + email not found → failure',
        build: () {
          when(
            () => validateEmailUseCase(any()),
          ).thenReturn(TaskEither.right(true));
          return buildBloc();
        },
        act: (bloc) => bloc.add(
          const AuthValidateEmailEvent(email: _tEmail, isLogin: true),
        ),
        expect: () => [
          isA<AuthValidateEmailLoadingState>(),
          isA<AuthValidateEmailFailureState>().having(
            (s) => s.failure.message,
            'message',
            'errors.email_not_found',
          ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'sign-up + email available → success',
        build: () {
          when(
            () => validateEmailUseCase(any()),
          ).thenReturn(TaskEither.right(true));
          return buildBloc();
        },
        act: (bloc) => bloc.add(
          const AuthValidateEmailEvent(email: _tEmail, isLogin: false),
        ),
        expect: () => [
          isA<AuthValidateEmailLoadingState>(),
          isA<AuthValidateEmailSuccessState>(),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'sign-up + email in use → failure',
        build: () {
          when(
            () => validateEmailUseCase(any()),
          ).thenReturn(TaskEither.right(false));
          return buildBloc();
        },
        act: (bloc) => bloc.add(
          const AuthValidateEmailEvent(email: _tEmail, isLogin: false),
        ),
        expect: () => [
          isA<AuthValidateEmailLoadingState>(),
          isA<AuthValidateEmailFailureState>().having(
            (s) => s.failure.message,
            'message',
            'errors.email_not_valid',
          ),
        ],
      );
    });

    // Email OTP verification (session start, onboarding hand-off) is now
    // owned by `AuthOtpVerifier` — see auth_otp_verifier_test.dart. `AuthBloc`
    // no longer has a verify-OTP event/state pair.

    // ── Logout ───────────────────────────────────────────────────────────

    group('AuthLogoutEvent', () {
      blocTest<AuthBloc, AuthState>(
        'emits [loading, success] and clears session on successful logout',
        build: () {
          when(
            () => logoutUseCase(any()),
          ).thenReturn(TaskEither<Failure, void>.right(null));
          return buildBloc();
        },
        act: (bloc) => bloc.add(AuthLogoutEvent()),
        expect: () => [
          isA<AuthLogoutLoadingState>(),
          isA<AuthLogoutSuccessState>(),
        ],
        verify: (_) {
          verify(() => sessionManager.logout()).called(1);
          expect(authStatusNotifier.status, AuthStatus.unauthenticated);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, failure] but still clears session on logout API error',
        build: () {
          when(
            () => logoutUseCase(any()),
          ).thenReturn(TaskEither.left(_tFailure));
          return buildBloc();
        },
        act: (bloc) => bloc.add(AuthLogoutEvent()),
        expect: () => [
          isA<AuthLogoutLoadingState>(),
          isA<AuthLogoutFailureState>(),
        ],
        verify: (_) {
          verify(() => sessionManager.logout()).called(1);
          expect(authStatusNotifier.status, AuthStatus.unauthenticated);
        },
      );
    });

    // ── CheckSignInStatus ─────────────────────────────────────────────────

    group('AuthCheckSignInStatusEvent', () {
      blocTest<AuthBloc, AuthState>(
        'emits [loading, success] when a valid session exists',
        build: () {
          when(
            () => checkSignInStatusUseCase(any()),
          ).thenReturn(TaskEither.right(_tUser));
          return buildBloc();
        },
        act: (bloc) => bloc.add(AuthCheckSignInStatusEvent()),
        expect: () => [
          isA<AuthCheckSignInStatusLoadingState>(),
          isA<AuthCheckSignInStatusSuccessState>().having(
            (s) => s.user,
            'user',
            _tUser,
          ),
        ],
        verify: (_) {
          expect(authStatusNotifier.status, AuthStatus.authenticated);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, failure] when session check returns null user',
        build: () {
          when(
            () => checkSignInStatusUseCase(any()),
          ).thenReturn(TaskEither<Failure, UserEntity?>.right(null));
          return buildBloc();
        },
        act: (bloc) => bloc.add(AuthCheckSignInStatusEvent()),
        expect: () => [
          isA<AuthCheckSignInStatusLoadingState>(),
          isA<AuthCheckSignInStatusFailureState>(),
        ],
        verify: (_) {
          expect(authStatusNotifier.status, AuthStatus.unauthenticated);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, failure] when session check throws a failure',
        build: () {
          when(
            () => checkSignInStatusUseCase(any()),
          ).thenReturn(TaskEither.left(_tFailure));
          return buildBloc();
        },
        act: (bloc) => bloc.add(AuthCheckSignInStatusEvent()),
        expect: () => [
          isA<AuthCheckSignInStatusLoadingState>(),
          isA<AuthCheckSignInStatusFailureState>(),
        ],
        verify: (_) {
          expect(authStatusNotifier.status, AuthStatus.unauthenticated);
        },
      );
    });

    // ── DeleteAccount ─────────────────────────────────────────────────────

    group('AuthDeleteAccountEvent', () {
      blocTest<AuthBloc, AuthState>(
        'emits [failure(user:null)] immediately when no user is in state',
        build: buildBloc,
        act: (bloc) => bloc.add(const AuthDeleteAccountEvent('sub-123')),
        expect: () => [
          isA<AuthDeleteAccountFailureState>().having(
            (s) => s.user,
            'user',
            null,
          ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, logout success] when account deletion succeeds',
        build: () {
          when(
            () => deleteAccountUseCase(any()),
          ).thenReturn(TaskEither<Failure, void>.right(null));
          return buildBloc();
        },
        seed: () => const AuthAuthenticatedState(_tUser),
        act: (bloc) => bloc.add(const AuthDeleteAccountEvent('sub-123')),
        expect: () => [
          isA<AuthDeleteAccountLoadingState>().having(
            (s) => s.user,
            'user',
            _tUser,
          ),
          isA<AuthLogoutSuccessState>(),
        ],
        verify: (_) {
          verify(() => sessionManager.logout()).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, failure] when account deletion API fails',
        build: () {
          when(
            () => deleteAccountUseCase(any()),
          ).thenReturn(TaskEither.left(_tFailure));
          return buildBloc();
        },
        seed: () => const AuthAuthenticatedState(_tUser),
        act: (bloc) => bloc.add(const AuthDeleteAccountEvent('sub-123')),
        expect: () => [
          isA<AuthDeleteAccountLoadingState>().having(
            (s) => s.user,
            'user',
            _tUser,
          ),
          isA<AuthDeleteAccountFailureState>()
              .having((s) => s.user, 'user', _tUser)
              .having(
                (s) => s.failure.message,
                'failure.message',
                'server_error',
              ),
        ],
      );
    });
  });
}
