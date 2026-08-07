import 'package:contact_verification/src/domain/entities/verification_dispatch.dart';
import 'package:contact_verification/src/domain/entities/verification_purpose.dart';
import 'package:contact_verification/src/domain/entities/verification_result.dart';
import 'package:contact_verification/src/domain/usecases/contact_verification_params.dart';
import 'package:contact_verification/src/domain/usecases/request_verification_usecase.dart';
import 'package:contact_verification/src/domain/usecases/resend_verification_usecase.dart';
import 'package:contact_verification/src/domain/usecases/verify_contact_usecase.dart';
import 'package:contact_verification/src/domain/verifiers/contact_verification_verifier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart' hide VerificationResult;

class _MockRequestUseCase extends Mock implements RequestVerificationUseCase {}

class _MockResendUseCase extends Mock implements ResendVerificationUseCase {}

class _MockVerifyUseCase extends Mock implements VerifyContactUseCase {}

void main() {
  late _MockRequestUseCase requestUseCase;
  late _MockResendUseCase resendUseCase;
  late _MockVerifyUseCase verifyUseCase;
  late ContactVerificationVerifier verifier;

  const purpose = VerificationPurpose.changeBusinessEmail;
  const target = 'new@biz.com';

  setUpAll(() {
    registerFallbackValue(
      const RequestVerificationParams(purpose: purpose, target: target),
    );
    registerFallbackValue(const ResendVerificationParams(purpose: purpose));
    registerFallbackValue(
      const VerifyContactParams(purpose: purpose, code: '000000'),
    );
  });

  setUp(() {
    requestUseCase = _MockRequestUseCase();
    resendUseCase = _MockResendUseCase();
    verifyUseCase = _MockVerifyUseCase();
    verifier = ContactVerificationVerifier(
      purpose: purpose,
      target: target,
      requestVerification: requestUseCase,
      resendVerification: resendUseCase,
      verifyContact: verifyUseCase,
    );
  });

  test(
    'requestCode calls request on the first call, resend afterwards',
    () async {
      when(() => requestUseCase(any())).thenAnswer(
        (_) => TaskEither.right(const VerificationDispatch(message: 'sent')),
      );
      when(() => resendUseCase(any())).thenAnswer(
        (_) =>
            TaskEither.right(const VerificationDispatch(message: 'resent')),
      );

      final first = await verifier.requestCode().run();
      final second = await verifier.requestCode().run();

      expect(first.isRight(), isTrue);
      expect(second.isRight(), isTrue);
      verify(
        () => requestUseCase(
          const RequestVerificationParams(purpose: purpose, target: target),
        ),
      ).called(1);
      verify(
        () => resendUseCase(const ResendVerificationParams(purpose: purpose)),
      ).called(1);
    },
  );

  test('requestCode surfaces the target as the masked destination', () async {
    when(() => requestUseCase(any())).thenAnswer(
      (_) => TaskEither.right(const VerificationDispatch(message: 'sent')),
    );

    final result = await verifier.requestCode().run();

    result.match(
      (_) => fail('expected success'),
      (delivery) => expect(delivery.maskedDestination, target),
    );
  });

  test(
    'verifyCode delegates to VerifyContactUseCase with the given code',
    () async {
      when(() => verifyUseCase(any())).thenAnswer(
        (_) => TaskEither.right(
          const VerificationResult(
            purpose: purpose,
            target: target,
            message: 'ok',
          ),
        ),
      );

      final result = await verifier.verifyCode('123456').run();

      expect(result.isRight(), isTrue);
      verify(
        () => verifyUseCase(
          const VerifyContactParams(purpose: purpose, code: '123456'),
        ),
      ).called(1);
    },
  );
}
