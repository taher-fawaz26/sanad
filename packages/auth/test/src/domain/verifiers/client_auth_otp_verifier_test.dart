import 'package:auth/src/domain/entities/client_auth_user_entity.dart';
import 'package:auth/src/domain/entities/client_verify_result_entity.dart';
import 'package:auth/src/domain/entities/resend_info_entity.dart';
import 'package:auth/src/domain/enums/auth_account_status.dart';
import 'package:auth/src/domain/enums/client_auth_method.dart';
import 'package:auth/src/domain/usecases/get_client_resend_info_usecase.dart';
import 'package:auth/src/domain/usecases/request_client_otp_usecase.dart';
import 'package:auth/src/domain/usecases/usecase_params.dart';
import 'package:auth/src/domain/usecases/verify_client_otp_usecase.dart';
import 'package:auth/src/domain/verifiers/client_auth_otp_verifier.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockRequestClientOtpUseCase extends Mock
    implements RequestClientOtpUseCase {}

class _MockVerifyClientOtpUseCase extends Mock
    implements VerifyClientOtpUseCase {}

class _MockGetClientResendInfoUseCase extends Mock
    implements GetClientResendInfoUseCase {}

void main() {
  late _MockRequestClientOtpUseCase requestOtp;
  late _MockVerifyClientOtpUseCase verifyOtp;
  late _MockGetClientResendInfoUseCase getResendInfo;
  late ClientAuthOtpVerifier verifier;

  const value = 'user@example.com';

  setUpAll(() {
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
  });

  setUp(() {
    requestOtp = _MockRequestClientOtpUseCase();
    verifyOtp = _MockVerifyClientOtpUseCase();
    getResendInfo = _MockGetClientResendInfoUseCase();
    verifier = ClientAuthOtpVerifier(
      method: ClientAuthMethod.email,
      value: value,
      requestOtp: requestOtp,
      verifyOtp: verifyOtp,
      getResendInfo: getResendInfo,
    );
  });

  test(
    'requestCode dispatches request-otp with the exact method/value',
    () async {
      when(() => requestOtp(any())).thenReturn(TaskEither.right(null));

      final result = await verifier.requestCode().run();

      expect(result.isRight(), isTrue);
      final captured =
          verify(() => requestOtp(captureAny())).captured.single
              as ClientOtpParams;
      expect(captured.method, ClientAuthMethod.email);
      expect(captured.value, value);
    },
  );

  test(
    'resendCode also hits request-otp (no separate resend endpoint)',
    () async {
      when(() => requestOtp(any())).thenReturn(TaskEither.right(null));

      await verifier.resendCode().run();

      verify(() => requestOtp(any())).called(1);
    },
  );

  test(
    'cooldown maps resend-info onto OtpCooldown (attemptsLeft → resendsLeft)',
    () async {
      when(() => getResendInfo(any())).thenReturn(
        TaskEither.right(
          const ResendInfo(
            canResend: false,
            remainingSeconds: 120,
            attemptsLeft: 2,
          ),
        ),
      );

      final result = await verifier.cooldown().run();

      result.match((f) => fail('expected right, got $f'), (cooldown) {
        expect(cooldown.canResend, isFalse);
        expect(cooldown.remainingSeconds, 120);
        expect(cooldown.resendsLeft, 2);
      });
    },
  );

  test(
    'verifyCode forwards the exact identifier + code and returns the result',
    () async {
      final expected = ClientVerifyResult(
        status: AuthAccountStatus.active,
        accessToken: 'a',
        refreshToken: 'r',
        user: const ClientAuthUser(id: 'c', preferredLanguage: 'en'),
      );
      when(() => verifyOtp(any())).thenReturn(TaskEither.right(expected));

      final result = await verifier.verifyCode('123456').run();

      expect(result.getRight().toNullable(), expected);
      final captured =
          verify(() => verifyOtp(captureAny())).captured.single
              as VerifyClientOtpParams;
      expect(captured.method, ClientAuthMethod.email);
      expect(captured.value, value);
      expect(captured.otp, '123456');
    },
  );

  test('verifyCode surfaces a failure unchanged', () async {
    when(() => verifyOtp(any())).thenReturn(
      TaskEither.left(const ValidationFailure(message: 'bad')),
    );

    final result = await verifier.verifyCode('000000').run();

    expect(result.isLeft(), isTrue);
  });
}
