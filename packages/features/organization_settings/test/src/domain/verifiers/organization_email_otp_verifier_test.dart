import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:organization_settings/src/domain/usecases/request_email_otp_usecase.dart';
import 'package:organization_settings/src/domain/usecases/verify_email_otp_usecase.dart';
import 'package:organization_settings/src/domain/verifiers/organization_email_otp_verifier.dart';

class _MockRequestUseCase extends Mock implements RequestEmailOtpUseCase {}

class _MockVerifyUseCase extends Mock implements VerifyEmailOtpUseCase {}

void main() {
  late _MockRequestUseCase requestOtp;
  late _MockVerifyUseCase verifyOtp;
  late OrganizationEmailOtpVerifier verifier;

  const email = 'ops@sanad.ae';

  setUpAll(() {
    registerFallbackValue(const RequestEmailOtpParams(email: email));
    registerFallbackValue(const VerifyEmailOtpParams(email: email, otp: '1234'));
  });

  setUp(() {
    requestOtp = _MockRequestUseCase();
    verifyOtp = _MockVerifyUseCase();
    verifier = OrganizationEmailOtpVerifier(
      email: email,
      requestOtp: requestOtp,
      verifyOtp: verifyOtp,
    );
  });

  test('requestCode maps a successful call to an OtpDelivery', () async {
    when(
      () => requestOtp(const RequestEmailOtpParams(email: email)),
    ).thenAnswer((_) => TaskEither.right(unit));

    final result = await verifier.requestCode().run();

    expect(result.isRight(), isTrue);
  });

  test('requestCode propagates a failure', () async {
    when(() => requestOtp(any())).thenAnswer(
      (_) => TaskEither.left(const ServerFailure(message: 'boom')),
    );

    final result = await verifier.requestCode().run();

    expect(result.isLeft(), isTrue);
  });

  test('verifyCode delegates to the use case with the given code', () async {
    when(
      () => verifyOtp(const VerifyEmailOtpParams(email: email, otp: '1234')),
    ).thenAnswer((_) => TaskEither.right(unit));

    final result = await verifier.verifyCode('1234').run();

    expect(result.isRight(), isTrue);
    verify(
      () => verifyOtp(const VerifyEmailOtpParams(email: email, otp: '1234')),
    ).called(1);
  });
}
