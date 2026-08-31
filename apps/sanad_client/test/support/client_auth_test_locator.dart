import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

/// Test doubles + a service-locator harness for the client auth flow.
///
/// The real `OAuthOtpPage`/`OAuthEmailPage`/`OAuthPhonePage`/`AccountSetupCubit`
/// resolve their use cases (and the session manager) from `sl`, so widget tests
/// register these mocks first. Sensible defaults let a "happy path" flow run
/// end to end (request succeeds → resend-info allows → verify returns an ACTIVE
/// session → GET /me → `clients/me` succeeds); individual tests override any
/// stub via the returned handles.
class MockRequestClientOtpUseCase extends Mock
    implements RequestClientOtpUseCase {}

class MockVerifyClientOtpUseCase extends Mock
    implements VerifyClientOtpUseCase {}

class MockGetClientResendInfoUseCase extends Mock
    implements GetClientResendInfoUseCase {}

class MockUpdateClientProfileUseCase extends Mock
    implements UpdateClientProfileUseCase {}

class MockGetCurrentUserUseCase extends Mock implements GetCurrentUserUseCase {}

class MockSessionManager extends Mock implements SessionManager {}

/// Handles to the registered mocks so a test can override a default stub.
class ClientAuthMocks {
  ClientAuthMocks({
    required this.requestOtp,
    required this.verifyOtp,
    required this.resendInfo,
    required this.updateProfile,
    required this.getCurrentUser,
    required this.sessionManager,
  });

  final MockRequestClientOtpUseCase requestOtp;
  final MockVerifyClientOtpUseCase verifyOtp;
  final MockGetClientResendInfoUseCase resendInfo;
  final MockUpdateClientProfileUseCase updateProfile;
  final MockGetCurrentUserUseCase getCurrentUser;
  final MockSessionManager sessionManager;
}

/// A default ACTIVE verify result. Pass [name] `null` to simulate a first-time
/// client (drives Enter Name); a non-null [name] simulates a returning client.
ClientVerifyResult activeVerifyResult({String? name = 'Mohamed Shahat'}) =>
    ClientVerifyResult(
      status: AuthAccountStatus.active,
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      user: ClientAuthUser(id: 'client-1', name: name, preferredLanguage: 'en'),
    );

const _fallbackIdentity = AuthIdentity(
  id: 'client-1',
  email: null,
  userType: UserType.client,
  permissions: [],
);

AuthSessionEntity _sessionBuilder(AuthSessionEntity session) => session;

/// Registers mocktail fallbacks for the custom argument types. Call once from
/// `setUpAll`.
void registerClientAuthFallbacks() {
  registerFallbackValue(
    const ClientOtpParams(method: ClientAuthMethod.email, value: ''),
  );
  registerFallbackValue(
    const VerifyClientOtpParams(
      method: ClientAuthMethod.email,
      value: '',
      otp: '',
    ),
  );
  registerFallbackValue(const UpdateClientProfileParams(name: ''));
  registerFallbackValue(const NoParams());
  registerFallbackValue(_fallbackIdentity);
  registerFallbackValue(_sessionBuilder);
}

/// Registers the mocks in `sl` with happy-path defaults and returns handles.
///
/// [verifyResult] defaults to an ACTIVE first-time client (name `null`).
ClientAuthMocks registerClientAuthMocks({ClientVerifyResult? verifyResult}) {
  final mocks = ClientAuthMocks(
    requestOtp: MockRequestClientOtpUseCase(),
    verifyOtp: MockVerifyClientOtpUseCase(),
    resendInfo: MockGetClientResendInfoUseCase(),
    updateProfile: MockUpdateClientProfileUseCase(),
    getCurrentUser: MockGetCurrentUserUseCase(),
    sessionManager: MockSessionManager(),
  );

  when(
    () => mocks.requestOtp(any()),
  ).thenReturn(TaskEither.right(null));
  when(() => mocks.resendInfo(any())).thenReturn(
    TaskEither.right(
      const ResendInfo(canResend: true, remainingSeconds: 0, attemptsLeft: 3),
    ),
  );
  when(() => mocks.verifyOtp(any())).thenReturn(
    TaskEither.right(verifyResult ?? activeVerifyResult(name: null)),
  );
  when(() => mocks.updateProfile(any())).thenReturn(
    TaskEither.right(
      const ClientProfile(
        id: 'client-1',
        name: 'Mohamed Shahat',
        preferredLanguage: 'en',
      ),
    ),
  );
  when(() => mocks.getCurrentUser(any())).thenReturn(
    TaskEither.right(
      const AuthIdentity(
        id: 'client-1',
        email: null,
        userType: UserType.client,
        permissions: [],
      ),
    ),
  );
  when(
    () => mocks.sessionManager.primeTokens(
      accessToken: any(named: 'accessToken'),
      refreshToken: any(named: 'refreshToken'),
    ),
  ).thenAnswer((_) async {});
  when(
    () => mocks.sessionManager.saveFromIdentity(
      accessToken: any(named: 'accessToken'),
      refreshToken: any(named: 'refreshToken'),
      identity: any(named: 'identity'),
    ),
  ).thenAnswer((_) async {});
  when(() => mocks.sessionManager.update(any())).thenAnswer((_) async => null);

  sl
    ..registerSingleton<RequestClientOtpUseCase>(mocks.requestOtp)
    ..registerSingleton<VerifyClientOtpUseCase>(mocks.verifyOtp)
    ..registerSingleton<GetClientResendInfoUseCase>(mocks.resendInfo)
    ..registerSingleton<UpdateClientProfileUseCase>(mocks.updateProfile)
    ..registerSingleton<GetCurrentUserUseCase>(mocks.getCurrentUser)
    ..registerSingleton<SessionManager>(mocks.sessionManager);

  return mocks;
}

/// Removes everything [registerClientAuthMocks] registered. Call from
/// `tearDown`.
void unregisterClientAuthMocks() {
  void drop<T extends Object>() {
    if (sl.isRegistered<T>()) sl.unregister<T>();
  }

  drop<RequestClientOtpUseCase>();
  drop<VerifyClientOtpUseCase>();
  drop<GetClientResendInfoUseCase>();
  drop<UpdateClientProfileUseCase>();
  drop<GetCurrentUserUseCase>();
  drop<SessionManager>();
}
