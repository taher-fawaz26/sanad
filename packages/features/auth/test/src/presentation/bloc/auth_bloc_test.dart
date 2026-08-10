// ignore_for_file: prefer_const_constructors // blocTest act: lambdas prevent Dart from inferring const at call-sites

import 'package:auth/src/auth/auth_status.dart';
import 'package:auth/src/auth/auth_status_notifier.dart';
import 'package:auth/src/domain/entities/auth_identity_entity.dart';
import 'package:auth/src/domain/entities/auth_response_entity.dart';
import 'package:auth/src/domain/entities/login_result_entity.dart';
import 'package:auth/src/domain/entities/resend_info_entity.dart';
import 'package:auth/src/domain/entities/user_entity.dart';
import 'package:auth/src/domain/enums/auth_account_status.dart';
import 'package:auth/src/domain/enums/auth_flow_intent.dart';
import 'package:auth/src/domain/enums/auth_session_status.dart';
import 'package:auth/src/domain/enums/user_type.dart';
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
import 'package:auth/src/presentation/bloc/auth/auth_bloc.dart';
import 'package:auth/src/session/session_manager.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

// ── Mocks ──────────────────────────────────────────────────────────────────

class _MockRequestSignupOtpUseCase extends Mock
    implements RequestSignupOtpUseCase {}

class _MockRequestLoginOtpUseCase extends Mock
    implements RequestLoginOtpUseCase {}

class _MockResendOtpUseCase extends Mock implements ResendOtpUseCase {}

class _MockGetResendInfoUseCase extends Mock implements GetResendInfoUseCase {}

class _MockLogoutUseCase extends Mock implements AuthLogoutUseCase {}

class _MockDeleteAccountUseCase extends Mock implements DeleteAccountUseCase {}

class _MockSessionManager extends Mock implements SessionManager {}

class _MockCheckSignInStatusUseCase extends Mock
    implements AuthCheckSignInStatusUseCase {}

class _MockSocialSignupUseCase extends Mock implements SocialSignupUseCase {}

class _MockSocialLoginUseCase extends Mock implements SocialLoginUseCase {}

class _MockGetCurrentUserUseCase extends Mock
    implements GetCurrentUserUseCase {}

class _FakeAuthSession extends Fake implements AuthSessionEntity {}

// ── Fixture data ───────────────────────────────────────────────────────────

const _tEmail = 'user@example.com';

const _tUser = UserEntity(
  id: 'sub-123',
  email: _tEmail,
  isVerified: true,
  isActive: true,
  type: UserType.client,
);

const _tIdentity = AuthIdentity(
  id: 'sub-123',
  email: _tEmail,
  userType: UserType.client,
  permissions: ['*'],
);

const _tFailure = ServerFailure(message: 'server_error');

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  late _MockRequestSignupOtpUseCase requestSignupOtpUseCase;
  late _MockRequestLoginOtpUseCase requestLoginOtpUseCase;
  late _MockResendOtpUseCase resendOtpUseCase;
  late _MockGetResendInfoUseCase getResendInfoUseCase;
  late _MockLogoutUseCase logoutUseCase;
  late _MockDeleteAccountUseCase deleteAccountUseCase;
  late _MockSessionManager sessionManager;
  late _MockCheckSignInStatusUseCase checkSignInStatusUseCase;
  late _MockSocialSignupUseCase socialSignupUseCase;
  late _MockSocialLoginUseCase socialLoginUseCase;
  late _MockGetCurrentUserUseCase getCurrentUserUseCase;
  late AuthStatusNotifier authStatusNotifier;

  AuthBloc buildBloc() => AuthBloc(
    requestSignupOtpUseCase: requestSignupOtpUseCase,
    requestLoginOtpUseCase: requestLoginOtpUseCase,
    resendOtpUseCase: resendOtpUseCase,
    getResendInfoUseCase: getResendInfoUseCase,
    logoutUseCase: logoutUseCase,
    deleteAccountUseCase: deleteAccountUseCase,
    sessionManager: sessionManager,
    checkSignInStatusUseCase: checkSignInStatusUseCase,
    authStatusNotifier: authStatusNotifier,
    socialSignupUseCase: socialSignupUseCase,
    socialLoginUseCase: socialLoginUseCase,
    getCurrentUserUseCase: getCurrentUserUseCase,
  );

  setUpAll(() {
    registerFallbackValue(const RequestEmailOtpParams(email: ''));
    registerFallbackValue(const DeleteAccountParams(userSub: ''));
    registerFallbackValue(const NoParams());
    registerFallbackValue(_FakeAuthSession());
    registerFallbackValue(_tIdentity);
  });

  setUp(() {
    requestSignupOtpUseCase = _MockRequestSignupOtpUseCase();
    requestLoginOtpUseCase = _MockRequestLoginOtpUseCase();
    resendOtpUseCase = _MockResendOtpUseCase();
    getResendInfoUseCase = _MockGetResendInfoUseCase();
    logoutUseCase = _MockLogoutUseCase();
    deleteAccountUseCase = _MockDeleteAccountUseCase();
    sessionManager = _MockSessionManager();
    checkSignInStatusUseCase = _MockCheckSignInStatusUseCase();
    socialSignupUseCase = _MockSocialSignupUseCase();
    socialLoginUseCase = _MockSocialLoginUseCase();
    getCurrentUserUseCase = _MockGetCurrentUserUseCase();
    authStatusNotifier = AuthStatusNotifier();

    when(() => sessionManager.save(any())).thenAnswer((_) async {});
    when(() => sessionManager.clear()).thenAnswer((_) async {});
    when(
      () => sessionManager.hydrateIdentity(any()),
    ).thenAnswer((_) async => null);
    when(
      () => sessionManager.primeTokens(
        accessToken: any(named: 'accessToken'),
        refreshToken: any(named: 'refreshToken'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => sessionManager.saveFromIdentity(
        accessToken: any(named: 'accessToken'),
        refreshToken: any(named: 'refreshToken'),
        identity: any(named: 'identity'),
      ),
    ).thenAnswer((_) async {});
  });

  group('AuthBloc', () {
    test('initial state is AuthInitialState', () {
      expect(buildBloc().state, isA<AuthInitialState>());
    });

    // ── Request OTP ────────────────────────────────────────────────────────

    group('AuthRequestOtpEvent', () {
      blocTest<AuthBloc, AuthState>(
        'signIn intent calls RequestLoginOtpUseCase and emits [loading, sent]',
        build: () {
          when(
            () => requestLoginOtpUseCase(any()),
          ).thenReturn(TaskEither<Failure, void>.right(null));
          return buildBloc();
        },
        act: (bloc) => bloc.add(
          const AuthRequestOtpEvent(
            email: _tEmail,
            intent: AuthFlowIntent.signIn,
          ),
        ),
        expect: () => [
          isA<AuthOtpRequestLoadingState>(),
          isA<AuthOtpSentState>()
              .having((s) => s.email, 'email', _tEmail)
              .having((s) => s.intent, 'intent', AuthFlowIntent.signIn),
        ],
        verify: (_) {
          verify(() => requestLoginOtpUseCase(any())).called(1);
          verifyNever(() => requestSignupOtpUseCase(any()));
        },
      );

      blocTest<AuthBloc, AuthState>(
        'createAccount intent calls RequestSignupOtpUseCase',
        build: () {
          when(
            () => requestSignupOtpUseCase(any()),
          ).thenReturn(TaskEither<Failure, void>.right(null));
          return buildBloc();
        },
        act: (bloc) => bloc.add(
          const AuthRequestOtpEvent(
            email: _tEmail,
            intent: AuthFlowIntent.createAccount,
          ),
        ),
        expect: () => [
          isA<AuthOtpRequestLoadingState>(),
          isA<AuthOtpSentState>().having(
            (s) => s.intent,
            'intent',
            AuthFlowIntent.createAccount,
          ),
        ],
        verify: (_) {
          verify(() => requestSignupOtpUseCase(any())).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, failure] when the OTP request fails (e.g. 404/409)',
        build: () {
          when(
            () => requestLoginOtpUseCase(any()),
          ).thenReturn(TaskEither.left(_tFailure));
          return buildBloc();
        },
        act: (bloc) => bloc.add(
          const AuthRequestOtpEvent(
            email: _tEmail,
            intent: AuthFlowIntent.signIn,
          ),
        ),
        expect: () => [
          isA<AuthOtpRequestLoadingState>(),
          isA<AuthOtpRequestFailureState>(),
        ],
      );
    });

    // ── Resend ─────────────────────────────────────────────────────────────

    group('AuthResendOtpEvent / AuthResendInfoRequestedEvent', () {
      blocTest<AuthBloc, AuthState>(
        'resend success emits AuthOtpSentState',
        build: () {
          when(
            () => resendOtpUseCase(any()),
          ).thenReturn(TaskEither<Failure, void>.right(null));
          return buildBloc();
        },
        act: (bloc) => bloc.add(const AuthResendOtpEvent(_tEmail)),
        expect: () => [isA<AuthOtpSentState>()],
      );

      blocTest<AuthBloc, AuthState>(
        'resend-info success emits AuthResendInfoState',
        build: () {
          when(() => getResendInfoUseCase(any())).thenReturn(
            TaskEither.right(
              const ResendInfo(
                canResend: false,
                remainingSeconds: 42,
                attemptsLeft: 2,
              ),
            ),
          );
          return buildBloc();
        },
        act: (bloc) => bloc.add(const AuthResendInfoRequestedEvent(_tEmail)),
        expect: () => [
          isA<AuthResendInfoState>().having(
            (s) => s.resendInfo.remainingSeconds,
            'remainingSeconds',
            42,
          ),
        ],
      );
    });

    // Email OTP verification (session start, onboarding hand-off) is now
    // called directly from `EmailOtpPage` — the two verify endpoints have
    // different response shapes and no longer fit a shared Bloc event.

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
          verify(() => sessionManager.clear()).called(1);
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
          verify(() => sessionManager.clear()).called(1);
        },
      );
    });

    // ── CheckSignInStatus ─────────────────────────────────────────────────

    group('AuthCheckSignInStatusEvent', () {
      blocTest<AuthBloc, AuthState>(
        'emits [loading, success] and hydrates identity when a session exists',
        build: () {
          when(
            () => checkSignInStatusUseCase(any()),
          ).thenReturn(TaskEither.right(_tUser));
          when(
            () => getCurrentUserUseCase(any()),
          ).thenReturn(TaskEither.right(_tIdentity));
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
          verify(() => sessionManager.hydrateIdentity(_tIdentity)).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'a failed GET /me does not block an otherwise-valid local session',
        build: () {
          when(
            () => checkSignInStatusUseCase(any()),
          ).thenReturn(TaskEither.right(_tUser));
          when(
            () => getCurrentUserUseCase(any()),
          ).thenReturn(TaskEither.left(_tFailure));
          return buildBloc();
        },
        act: (bloc) => bloc.add(AuthCheckSignInStatusEvent()),
        expect: () => [
          isA<AuthCheckSignInStatusLoadingState>(),
          isA<AuthCheckSignInStatusSuccessState>(),
        ],
        verify: (_) {
          verifyNever(() => sessionManager.hydrateIdentity(any()));
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
          verify(() => sessionManager.clear()).called(1);
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

    // ── Google Sign-In ─────────────────────────────────────────────────────

    group('AuthGoogleSignInEvent', () {
      blocTest<AuthBloc, AuthState>(
        'createAccount + onboarding response emits AuthOnboardingRequiredState',
        build: () {
          when(() => socialSignupUseCase(any())).thenReturn(
            TaskEither.right(
              const OnboardingAuthEntity(
                status: AuthSessionStatus.onboarding,
                onboardingToken: 'onboarding-token',
                isEmailVerified: false,
                isProfileCreated: false,
                user: _tUser,
              ),
            ),
          );
          return buildBloc();
        },
        act: (bloc) => bloc.add(
          const AuthGoogleSignInEvent(AuthFlowIntent.createAccount),
        ),
        expect: () => [
          isA<AuthGoogleSignInLoadingState>(),
          isA<AuthOnboardingRequiredState>().having(
            (s) => s.onboardingToken,
            'onboardingToken',
            'onboarding-token',
          ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'signIn + ACTIVE composes a session via GET /me and emits authenticated',
        build: () {
          when(() => socialLoginUseCase(any())).thenReturn(
            TaskEither.right(
              const LoginResult(
                status: AuthAccountStatus.active,
                accessToken: 'access-token',
                refreshToken: 'refresh-token',
              ),
            ),
          );
          when(
            () => getCurrentUserUseCase(any()),
          ).thenReturn(TaskEither.right(_tIdentity));
          return buildBloc();
        },
        act: (bloc) =>
            bloc.add(const AuthGoogleSignInEvent(AuthFlowIntent.signIn)),
        expect: () => [
          isA<AuthGoogleSignInLoadingState>(),
          isA<AuthAuthenticatedState>(),
        ],
        verify: (_) {
          verify(
            () => sessionManager.primeTokens(
              accessToken: 'access-token',
              refreshToken: 'refresh-token',
            ),
          ).called(1);
          verify(
            () => sessionManager.saveFromIdentity(
              accessToken: 'access-token',
              refreshToken: 'refresh-token',
              identity: _tIdentity,
            ),
          ).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'signIn + SUSPENDED emits AuthSuspendedState',
        build: () {
          when(() => socialLoginUseCase(any())).thenReturn(
            TaskEither.right(
              const LoginResult(status: AuthAccountStatus.suspended),
            ),
          );
          return buildBloc();
        },
        act: (bloc) =>
            bloc.add(const AuthGoogleSignInEvent(AuthFlowIntent.signIn)),
        expect: () => [
          isA<AuthGoogleSignInLoadingState>(),
          isA<AuthSuspendedState>(),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'signIn + failure emits AuthGoogleSignInFailureState',
        build: () {
          when(
            () => socialLoginUseCase(any()),
          ).thenReturn(TaskEither.left(_tFailure));
          return buildBloc();
        },
        act: (bloc) =>
            bloc.add(const AuthGoogleSignInEvent(AuthFlowIntent.signIn)),
        expect: () => [
          isA<AuthGoogleSignInLoadingState>(),
          isA<AuthGoogleSignInFailureState>(),
        ],
      );
    });
  });
}
