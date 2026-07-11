// ignore_for_file: prefer_const_constructors // blocTest act: lambdas prevent Dart from inferring const at call-sites

import 'package:auth/src/auth/auth_status.dart';
import 'package:auth/src/auth/auth_status_notifier.dart';
import 'package:auth/src/domain/entities/login_response_entity.dart';
import 'package:auth/src/domain/entities/user_entity.dart';
import 'package:auth/src/domain/enums/user_type.dart';
import 'package:auth/src/domain/usecases/check_signin_status_usecase.dart';
import 'package:auth/src/domain/usecases/delete_account_usecase.dart';
import 'package:auth/src/domain/usecases/login_usecase.dart';
import 'package:auth/src/domain/usecases/logout_usecase.dart';
import 'package:auth/src/domain/usecases/register_usecase.dart';
import 'package:auth/src/domain/usecases/usecase_params.dart';
import 'package:auth/src/presentation/bloc/auth/auth_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:network/network.dart';

// ── Mocks ──────────────────────────────────────────────────────────────────

class _MockLoginUseCase extends Mock implements AuthLoginUseCase {}

class _MockLogoutUseCase extends Mock implements AuthLogoutUseCase {}

class _MockDeleteAccountUseCase extends Mock implements DeleteAccountUseCase {}

class _MockRegisterUseCase extends Mock implements AuthRegisterUseCase {}

class _MockSessionManager extends Mock implements SessionManager {}

class _MockCheckSignInStatusUseCase extends Mock
    implements AuthCheckSignInStatusUseCase {}

// ── Fixture data ───────────────────────────────────────────────────────────

const _tUser = UserEntity(
  sub: 'sub-123',
  identifier: 'user@example.com',
  identifierType: 'email',
  isVerified: true,
  isProfileCompleted: true,
  type: UserType.client,
);

const _tLoginResponse = LoginResponseEntity(
  accessToken: 'access-token',
  refreshToken: 'refresh-token',
  user: _tUser,
);

const _tFailure = ServerFailure(message: 'server_error');

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  late _MockLoginUseCase loginUseCase;
  late _MockLogoutUseCase logoutUseCase;
  late _MockDeleteAccountUseCase deleteAccountUseCase;
  late _MockRegisterUseCase registerUseCase;
  late _MockSessionManager sessionManager;
  late _MockCheckSignInStatusUseCase checkSignInStatusUseCase;
  late AuthStatusNotifier authStatusNotifier;

  AuthBloc buildBloc() => AuthBloc(
        loginUseCase: loginUseCase,
        logoutUseCase: logoutUseCase,
        deleteAccountUseCase: deleteAccountUseCase,
        registerUseCase: registerUseCase,
        sessionManager: sessionManager,
        checkSignInStatusUseCase: checkSignInStatusUseCase,
        authStatusNotifier: authStatusNotifier,
      );

  setUpAll(() {
    registerFallbackValue(const LoginParams(identifier: '', password: ''));
    registerFallbackValue(
      const RegisterParams(
          identifier: '', password: '', type: UserType.client),
    );
    registerFallbackValue(const DeleteAccountParams(userSub: ''));
    registerFallbackValue(const NoParams());
  });

  setUp(() {
    loginUseCase = _MockLoginUseCase();
    logoutUseCase = _MockLogoutUseCase();
    deleteAccountUseCase = _MockDeleteAccountUseCase();
    registerUseCase = _MockRegisterUseCase();
    sessionManager = _MockSessionManager();
    checkSignInStatusUseCase = _MockCheckSignInStatusUseCase();
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

    // ── Login ────────────────────────────────────────────────────────────

    group('AuthLoginEvent', () {
      blocTest<AuthBloc, AuthState>(
        'emits [loading, success] when login succeeds',
        build: () {
          when(() => loginUseCase(any()))
              .thenReturn(TaskEither.right(_tLoginResponse));
          return buildBloc();
        },
        act: (bloc) =>
            bloc.add(const AuthLoginEvent('user@example.com', 'password')),
        expect: () => [
          isA<AuthLoginLoadingState>(),
          isA<AuthLoginSuccessState>().having((s) => s.user, 'user', _tUser),
        ],
        verify: (_) {
          expect(authStatusNotifier.status, AuthStatus.authenticated);
          verify(
            () => sessionManager.startSession(
              accessToken: 'access-token',
              refreshToken: 'refresh-token',
            ),
          ).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, failure] when login fails',
        build: () {
          when(() => loginUseCase(any()))
              .thenReturn(TaskEither.left(_tFailure));
          return buildBloc();
        },
        act: (bloc) =>
            bloc.add(const AuthLoginEvent('user@example.com', 'password')),
        expect: () => [
          isA<AuthLoginLoadingState>(),
          isA<AuthLoginFailureState>()
              .having((s) => s.message, 'message', 'server_error'),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, unverified] when login returns UnverifiedUserFailure',
        build: () {
          when(() => loginUseCase(any())).thenReturn(
            TaskEither.left(
              const UnverifiedUserFailure(message: 'unverified'),
            ),
          );
          return buildBloc();
        },
        act: (bloc) =>
            bloc.add(const AuthLoginEvent('user@example.com', 'password')),
        expect: () => [
          isA<AuthLoginLoadingState>(),
          isA<AuthLoginUnverifiedState>(),
        ],
      );
    });

    // ── Logout ───────────────────────────────────────────────────────────

    group('AuthLogoutEvent', () {
      blocTest<AuthBloc, AuthState>(
        'emits [loading, success] and clears session on successful logout',
        build: () {
          when(() => logoutUseCase(any()))
              .thenReturn(TaskEither<Failure, void>.right(null));
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
          when(() => logoutUseCase(any()))
              .thenReturn(TaskEither.left(_tFailure));
          return buildBloc();
        },
        act: (bloc) => bloc.add(AuthLogoutEvent()),
        expect: () => [
          isA<AuthLogoutLoadingState>(),
          isA<AuthLogoutFailureState>(),
        ],
        verify: (_) {
          // Session must be cleared even when the API call fails
          verify(() => sessionManager.logout()).called(1);
          expect(authStatusNotifier.status, AuthStatus.unauthenticated);
        },
      );
    });

    // ── Register ─────────────────────────────────────────────────────────

    group('AuthRegisterEvent', () {
      blocTest<AuthBloc, AuthState>(
        'emits [loading, success] when register succeeds',
        build: () {
          when(() => registerUseCase(any()))
              .thenReturn(TaskEither<Failure, void>.right(null));
          return buildBloc();
        },
        act: (bloc) => bloc.add(
          const AuthRegisterEvent(
              'user@example.com', 'password', UserType.client),
        ),
        expect: () => [
          isA<AuthRegisterLoadingState>(),
          isA<AuthRegisterSuccessState>(),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, failure] when register fails',
        build: () {
          when(() => registerUseCase(any()))
              .thenReturn(TaskEither.left(_tFailure));
          return buildBloc();
        },
        act: (bloc) => bloc.add(
          const AuthRegisterEvent(
              'user@example.com', 'password', UserType.client),
        ),
        expect: () => [
          isA<AuthRegisterLoadingState>(),
          isA<AuthRegisterFailureState>()
              .having((s) => s.message, 'message', 'server_error'),
        ],
      );
    });

    // ── CheckSignInStatus ─────────────────────────────────────────────────

    group('AuthCheckSignInStatusEvent', () {
      blocTest<AuthBloc, AuthState>(
        'emits [loading, success] when a valid session exists',
        build: () {
          when(() => checkSignInStatusUseCase(any()))
              .thenReturn(TaskEither.right(_tUser));
          return buildBloc();
        },
        act: (bloc) => bloc.add(AuthCheckSignInStatusEvent()),
        expect: () => [
          isA<AuthCheckSignInStatusLoadingState>(),
          isA<AuthCheckSignInStatusSuccessState>()
              .having((s) => s.user, 'user', _tUser),
        ],
        verify: (_) {
          expect(authStatusNotifier.status, AuthStatus.authenticated);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, failure] when session check returns null user',
        build: () {
          when(() => checkSignInStatusUseCase(any()))
              .thenReturn(TaskEither<Failure, UserEntity?>.right(null));
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
          when(() => checkSignInStatusUseCase(any()))
              .thenReturn(TaskEither.left(_tFailure));
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
          isA<AuthDeleteAccountFailureState>()
              .having((s) => s.user, 'user', null),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, logout success] when account deletion succeeds',
        build: () {
          when(() => deleteAccountUseCase(any()))
              .thenReturn(TaskEither<Failure, void>.right(null));
          return buildBloc();
        },
        seed: () => const AuthLoginSuccessState(_tUser),
        act: (bloc) => bloc.add(const AuthDeleteAccountEvent('sub-123')),
        expect: () => [
          isA<AuthDeleteAccountLoadingState>()
              .having((s) => s.user, 'user', _tUser),
          isA<AuthLogoutSuccessState>(),
        ],
        verify: (_) {
          verify(() => sessionManager.logout()).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, failure] when account deletion API fails',
        build: () {
          when(() => deleteAccountUseCase(any()))
              .thenReturn(TaskEither.left(_tFailure));
          return buildBloc();
        },
        seed: () => const AuthLoginSuccessState(_tUser),
        act: (bloc) => bloc.add(const AuthDeleteAccountEvent('sub-123')),
        expect: () => [
          isA<AuthDeleteAccountLoadingState>()
              .having((s) => s.user, 'user', _tUser),
          isA<AuthDeleteAccountFailureState>()
              .having((s) => s.user, 'user', _tUser)
              .having((s) => s.message, 'message', 'server_error'),
        ],
      );
    });
  });
}
