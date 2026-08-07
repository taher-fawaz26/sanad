import 'package:auth/src/data/models/profiles/auth_profile_model.dart';
import 'package:auth/src/domain/entities/auth_response_entity.dart';
import 'package:auth/src/domain/entities/user_entity.dart';
import 'package:auth/src/domain/enums/auth_session_status.dart';
import 'package:auth/src/domain/enums/user_type.dart';
import 'package:auth/src/domain/usecases/request_email_otp_usecase.dart';
import 'package:auth/src/domain/usecases/usecase_params.dart';
import 'package:auth/src/domain/usecases/verify_email_otp_usecase.dart';
import 'package:auth/src/domain/verifiers/auth_otp_verifier.dart';
import 'package:auth/src/session/session_manager.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockRequestOtpUseCase extends Mock implements RequestEmailOtpUseCase {}

class _MockVerifyOtpUseCase extends Mock implements VerifyEmailOtpUseCase {}

class _MockSessionManager extends Mock implements SessionManager {}

class _FakeAuthSession extends Fake implements AuthSessionEntity {}

const _tEmail = 'user@example.com';

const _tUser = UserEntity(
  id: 'sub-123',
  email: _tEmail,
  isVerified: true,
  isActive: true,
  type: UserType.client,
);

const _tProfile = ClientProfileModel(
  id: 'profile-1',
  fullName: 'Test User',
  email: _tEmail,
  emiratesId: '784-0000-0000000-0',
);

const _tAuthenticated = AuthSessionEntity(
  accessToken: 'access-token',
  refreshToken: 'refresh-token',
  status: AuthSessionStatus.authenticated,
  isEmailVerified: true,
  isProfileCreated: true,
  user: _tUser,
  profile: _tProfile,
  permissions: [],
);

const _tOnboarding = OnboardingAuthEntity(
  status: AuthSessionStatus.onboarding,
  onboardingToken: 'onboarding-token',
  isEmailVerified: true,
  isProfileCreated: false,
  user: _tUser,
);

void main() {
  late _MockRequestOtpUseCase requestOtpUseCase;
  late _MockVerifyOtpUseCase verifyOtpUseCase;
  late _MockSessionManager sessionManager;
  late AuthOtpVerifier verifier;

  setUpAll(() {
    registerFallbackValue(const RequestEmailOtpParams(email: ''));
    registerFallbackValue(const VerifyEmailOtpParams(email: '', otp: ''));
    registerFallbackValue(_FakeAuthSession());
  });

  setUp(() {
    requestOtpUseCase = _MockRequestOtpUseCase();
    verifyOtpUseCase = _MockVerifyOtpUseCase();
    sessionManager = _MockSessionManager();
    when(() => sessionManager.save(any())).thenAnswer((_) async {});

    verifier = AuthOtpVerifier(
      email: _tEmail,
      requestEmailOtp: requestOtpUseCase,
      verifyEmailOtp: verifyOtpUseCase,
      sessionManager: sessionManager,
    );
  });

  group('requestCode', () {
    test('maps a successful request to an OtpDelivery', () async {
      when(
        () => requestOtpUseCase(any()),
      ).thenReturn(TaskEither<Failure, void>.right(null));

      final result = await verifier.requestCode().run();

      expect(result.isRight(), isTrue);
      verify(
        () => requestOtpUseCase(const RequestEmailOtpParams(email: _tEmail)),
      ).called(1);
    });

    test('propagates a failure', () async {
      when(
        () => requestOtpUseCase(any()),
      ).thenReturn(TaskEither.left(const ServerFailure(message: 'nope')));

      final result = await verifier.requestCode().run();

      expect(result.isLeft(), isTrue);
    });
  });

  group('verifyCode', () {
    test('existing user hands the session to SessionManager.save', () async {
      when(
        () => verifyOtpUseCase(any()),
      ).thenReturn(TaskEither.right(_tAuthenticated));

      final result = await verifier.verifyCode('123456').run();

      expect(result, const Right<Failure, AuthResponseEntity>(_tAuthenticated));
      verify(() => sessionManager.save(_tAuthenticated)).called(1);
    });

    test('new user does not start a session', () async {
      when(
        () => verifyOtpUseCase(any()),
      ).thenReturn(TaskEither.right(_tOnboarding));

      final result = await verifier.verifyCode('123456').run();

      expect(result, const Right<Failure, AuthResponseEntity>(_tOnboarding));
      verifyNever(() => sessionManager.save(any()));
    });

    test(
      'propagates a verification failure without touching the session',
      () async {
        when(
          () => verifyOtpUseCase(any()),
        ).thenReturn(TaskEither.left(const ServerFailure(message: 'bad code')));

        final result = await verifier.verifyCode('000000').run();

        expect(result.isLeft(), isTrue);
        verifyNever(() => sessionManager.save(any()));
      },
    );
  });
}
