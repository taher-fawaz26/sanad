import 'package:contact_verification/contact_verification.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart' hide VerificationResult;
import 'package:otp/otp.dart';

class _MockRequestUseCase extends Mock implements RequestVerificationUseCase {}

class _MockResendUseCase extends Mock implements ResendVerificationUseCase {}

class _MockVerifyUseCase extends Mock implements VerifyContactUseCase {}

class _MockResendInfoUseCase extends Mock implements GetResendInfoUseCase {}

void main() {
  const purpose = VerificationPurpose.changeOwnerEmail;
  const target = 'owner@example.com';

  late _MockRequestUseCase requestUseCase;
  late _MockResendUseCase resendUseCase;
  late _MockVerifyUseCase verifyUseCase;
  late _MockResendInfoUseCase resendInfoUseCase;
  late ContactVerificationVerifier verifier;

  setUpAll(() {
    registerFallbackValue(
      const RequestVerificationParams(purpose: purpose, target: target),
    );
    registerFallbackValue(const ResendVerificationParams(purpose: purpose));
    registerFallbackValue(const ResendInfoParams(purpose: purpose));
    registerFallbackValue(
      const VerifyContactParams(purpose: purpose, code: '000000'),
    );
  });

  setUp(() {
    requestUseCase = _MockRequestUseCase();
    resendUseCase = _MockResendUseCase();
    verifyUseCase = _MockVerifyUseCase();
    resendInfoUseCase = _MockResendInfoUseCase();
    verifier = ContactVerificationVerifier(
      purpose: purpose,
      target: target,
      requestVerification: requestUseCase,
      resendVerification: resendUseCase,
      verifyContact: verifyUseCase,
      getResendInfo: resendInfoUseCase,
    );
  });

  void stubRequest() => when(() => requestUseCase(any())).thenAnswer(
    (_) => TaskEither.right(const VerificationDispatch(message: 'sent')),
  );
  void stubResend() => when(() => resendUseCase(any())).thenAnswer(
    (_) => TaskEither.right(const VerificationDispatch(message: 'resent')),
  );

  group('dispatch', () {
    test(
      'requestCode always opens a session via the request endpoint',
      () async {
        stubRequest();

        await verifier.requestCode().run();
        await verifier.requestCode().run();

        verify(() => requestUseCase(any())).called(2);
        verifyNever(() => resendUseCase(any()));
      },
    );

    test('resendCode uses the resend endpoint', () async {
      stubResend();

      final result = await verifier.resendCode().run();

      expect(result.isRight(), isTrue);
      verify(() => resendUseCase(any())).called(1);
      verifyNever(() => requestUseCase(any()));
    });

    test(
      'a failed first send never leaves the verifier stuck on resend '
      '(regression: an eagerly-set flag sent every retry to /resend against '
      'a session that was never created)',
      () async {
        when(() => requestUseCase(any())).thenAnswer(
          (_) => TaskEither.left(const ServerFailure(message: 'boom')),
        );

        final first = await verifier.requestCode().run();
        expect(first.isLeft(), isTrue);

        stubRequest();
        final second = await verifier.requestCode().run();

        expect(second.isRight(), isTrue);
        verifyNever(() => resendUseCase(any()));
      },
    );

    test(
      'resend falls back to opening a session when none is live (400)',
      () async {
        when(() => resendUseCase(any())).thenAnswer(
          (_) => TaskEither.left(
            const ValidationFailure(message: 'No active session'),
          ),
        );
        stubRequest();

        final result = await verifier.resendCode().run();

        expect(result.isRight(), isTrue, reason: 'recovered, not stranded');
        verify(() => resendUseCase(any())).called(1);
        verify(() => requestUseCase(any())).called(1);
      },
    );

    test(
      'resend falls back when the 400 arrives as a BusinessRuleFailure — the '
      'shape the backend actually sends (regression: matching only on '
      'ValidationFailure left this fallback unreachable, because ErrorMapper '
      "reserves that for a class-validator `message` array and this endpoint's "
      'rejection is a single string)',
      () async {
        when(() => resendUseCase(any())).thenAnswer(
          (_) => TaskEither.left(
            const BusinessRuleFailure(
              message: 'No active session for this purpose',
              code: '400',
            ),
          ),
        );
        stubRequest();

        final result = await verifier.resendCode().run();

        expect(result.isRight(), isTrue, reason: 'recovered, not stranded');
        verify(() => requestUseCase(any())).called(1);
      },
    );

    test('a conflict on resend is surfaced as-is, not retried', () async {
      when(() => resendUseCase(any())).thenAnswer(
        (_) => TaskEither.left(
          const ConflictFailure(message: 'Target no longer available'),
        ),
      );

      final result = await verifier.resendCode().run();

      expect(result.isLeft(), isTrue);
      verifyNever(() => requestUseCase(any()));
    });

    test('a non-recoverable resend failure is surfaced as-is', () async {
      when(() => resendUseCase(any())).thenAnswer(
        (_) => TaskEither.left(const RateLimitFailure(message: 'cooldown')),
      );

      final result = await verifier.resendCode().run();

      expect(result.isLeft(), isTrue);
      verifyNever(() => requestUseCase(any()));
    });
  });

  group('cooldown', () {
    test('maps resend-info onto the engine cooldown', () async {
      when(() => resendInfoUseCase(any())).thenAnswer(
        (_) => TaskEither.right(
          const VerificationResendInfo(
            canResend: false,
            remainingSeconds: 42,
            attemptsLeft: 3,
          ),
        ),
      );

      final result = await verifier.cooldown().run();

      expect(
        result.getOrElse((_) => OtpCooldown.unknown),
        const OtpCooldown(
          canResend: false,
          remainingSeconds: 42,
          // attemptsLeft counts RESENDS, not wrong-code tries.
          resendsLeft: 3,
        ),
      );
    });
  });

  group('verification', () {
    test('verifyCode passes the code through to the use case', () async {
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
    });
  });
}
