import 'package:auth/auth.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:network/network.dart';
import 'package:otp/otp.dart';

class _MockValidate extends Mock implements ValidateOtpUseCase {}

class _MockResend extends Mock implements ResendOtpUseCase {}

class _MockSession extends Mock implements SessionManager {}

class _FakeAuthStatusNotifier extends AuthStatusNotifier {
  int updateCalls = 0;
  AuthStatus? lastStatus;
  bool? lastProfileCompleted;

  @override
  void update(
    AuthStatus newStatus, {
    RegistrationStatus? registrationStatus,
    bool? isProfileCompleted,
    String? submittedReferenceNumber,
    bool clearSubmittedReference = false,
  }) {
    updateCalls++;
    lastStatus = newStatus;
    lastProfileCompleted = isProfileCompleted;
    super.update(
      newStatus,
      registrationStatus: registrationStatus,
      isProfileCompleted: isProfileCompleted,
      submittedReferenceNumber: submittedReferenceNumber,
      clearSubmittedReference: clearSubmittedReference,
    );
  }
}

const _identifier = '+971501234567';
const _otp = 123456;

const _user = UserEntity(
  sub: 'u1',
  identifier: _identifier,
  identifierType: 'phone',
  isVerified: true,
  isProfileCompleted: false,
  type: UserType.client,
);

const _loginResponse = LoginResponseEntity(
  accessToken: 'a-1',
  refreshToken: 'r-1',
  user: _user,
);

void main() {
  setUpAll(() {
    registerFallbackValue(
      const ValidateOtpParams(
        identifier: _identifier,
        otp: _otp,
        purpose: OtpPurpose.register,
      ),
    );
    registerFallbackValue(
      const ResendOtpParams(
        identifier: _identifier,
        purpose: OtpPurpose.register,
      ),
    );
  });

  late _MockValidate validate;
  late _MockResend resend;
  late _MockSession session;
  late _FakeAuthStatusNotifier notifier;

  OtpBloc build() => OtpBloc(
    validateOtpUseCase: validate,
    resendOtpUseCase: resend,
    sessionManager: session,
    authStatusNotifier: notifier,
  );

  setUp(() {
    validate = _MockValidate();
    resend = _MockResend();
    session = _MockSession();
    notifier = _FakeAuthStatusNotifier();
  });

  group('OtpBloc — validate', () {
    blocTest<OtpBloc, OtpState>(
      'emits [loading, success] and starts a session on happy path',
      setUp: () {
        when(() => validate(any())).thenAnswer(
          (_) => TaskEither.of(_loginResponse),
        );
        when(
          () => session.startSession(
            accessToken: 'a-1',
            refreshToken: 'r-1',
          ),
        ).thenAnswer((_) async {});
      },
      build: build,
      act: (bloc) => bloc.add(
        const OtpValidateEvent(identifier: _identifier, otp: _otp),
      ),
      expect: () => [
        const OtpValidateLoadingState(),
        isA<OtpValidateSuccessState>()
            .having((s) => s.user, 'user', _user)
            .having(
              (s) => s.message,
              'message',
              'otp.account_created_success',
            ),
      ],
      verify: (_) {
        verify(
          () => session.startSession(
            accessToken: 'a-1',
            refreshToken: 'r-1',
          ),
        ).called(1);
        expect(notifier.updateCalls, 1);
        expect(notifier.lastStatus, AuthStatus.authenticated);
        expect(notifier.lastProfileCompleted, false);
      },
    );

    blocTest<OtpBloc, OtpState>(
      'emits [loading, failure] and does not start a session on failure',
      setUp: () {
        when(() => validate(any())).thenAnswer(
          (_) => TaskEither.left(const NetworkFailure(message: 'bad code')),
        );
      },
      build: build,
      act: (bloc) => bloc.add(
        const OtpValidateEvent(identifier: _identifier, otp: _otp),
      ),
      expect: () => [
        const OtpValidateLoadingState(),
        isA<OtpValidateFailureState>(),
      ],
      verify: (_) {
        verifyNever(
          () => session.startSession(
            accessToken: any(named: 'accessToken'),
            refreshToken: any(named: 'refreshToken'),
          ),
        );
        expect(notifier.updateCalls, 0);
      },
    );
  });

  group('OtpBloc — resend', () {
    blocTest<OtpBloc, OtpState>(
      'emits [resendLoading, resendSuccess] on happy path',
      setUp: () {
        when(() => resend(any())).thenAnswer((_) => TaskEither.of(unit));
      },
      build: build,
      act: (bloc) => bloc.add(
        const OtpResendEvent(
          identifier: _identifier,
          purpose: OtpPurpose.register,
        ),
      ),
      expect: () => [
        const OtpResendLoadingState(),
        const OtpResendSuccessState(),
      ],
    );

    blocTest<OtpBloc, OtpState>(
      'emits [resendLoading, resendFailure] on failure',
      setUp: () {
        when(() => resend(any())).thenAnswer(
          (_) => TaskEither.left(const NetworkFailure(message: 'rate limit')),
        );
      },
      build: build,
      act: (bloc) => bloc.add(
        const OtpResendEvent(
          identifier: _identifier,
          purpose: OtpPurpose.register,
        ),
      ),
      expect: () => [
        const OtpResendLoadingState(),
        isA<OtpResendFailureState>(),
      ],
    );
  });
}
